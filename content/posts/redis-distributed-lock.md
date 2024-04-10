---
title: "Redis 分布式锁踩坑记"
date: 2024-04-10
categories: ["中间件"]
tags: ["Redis", "分布式", "锁"]
draft: false
---

# Redis 分布式锁踩坑记

分布式锁这个东西，面试必问，实际开发也经常用。我做课程项目的时候在这上面栽了好几个跟头，今天把踩过的坑总结一下。

## 最简单的实现：SETNX

分布式锁的核心思路很简单：大家抢同一个 key，谁抢到谁执行。

```bash
SETNX lock:order:1001 "locked"
DEL lock:order:1001
```

Java 代码：

```java
Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent("lock:order:" + orderId, "1");
if (Boolean.TRUE.equals(locked)) {
    try {
        doSomething();
    } finally {
        redisTemplate.delete("lock:order:" + orderId);
    }
}
```

看起来没问题？坑大了。

## 过期时间的坑

假设拿到锁之后服务器挂了，`finally` 里的 `delete` 没执行到——死锁。

所以得加过期时间：

```java
Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent("lock:order:" + orderId, "1", 30, TimeUnit.SECONDS);
```

注意一定要用 `SET key value EX seconds NX` 原子命令。别先 SETNX 再 EXPIRE，中间挂了还是死锁。我第一次写就犯了这个错。

但过期时间带来新问题：业务执行时间超过锁的过期时间咋办？锁过期了，别的线程拿到锁，两个线程同时在跑。

还有个更隐蔽的坑：A 的锁过期了，B 拿到锁，然后 A 执行完去 DEL，删的其实是 B 的锁。

解决误删要给 value 加唯一标识，删前先检查：

```java
String requestId = UUID.randomUUID().toString();
Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent("lock:order:" + orderId, requestId, 30, TimeUnit.SECONDS);

// Lua 脚本保证原子性
String script = "if redis.call('get', KEYS[1]) == ARGV[1] then " +
                "return redis.call('del', KEYS[1]) else return 0 end";
redisTemplate.execute(new DefaultRedisScript<>(script, Long.class),
    Collections.singletonList("lock:order:" + orderId), requestId);
```

为啥用 Lua？因为 GET 和 DEL 不是原子的，Lua 脚本在 Redis 里原子执行。

## Redisson 和看门狗机制

上面那些坑自己处理太累了。用 Redisson：

```java
RLock lock = redissonClient.getLock("lock:order:" + orderId);
try {
    if (lock.tryLock(5, TimeUnit.SECONDS)) {
        doSomething();
    }
} finally {
    if (lock.isHeldByCurrentThread()) {
        lock.unlock();
    }
}
```

Redisson 最牛的是看门狗（Watchdog）机制。不指定 leaseTime 的话，它会启动后台线程，每 10 秒检查一下（默认锁超时 30 秒的 1/3），还持有锁就自动续期。

这完美解决了"业务时间超过锁超时"的问题。业务没完，锁一直续；进程挂了，看门狗跟着没了，锁自然过期释放。

我踩过一个坑：`tryLock` 指定了 leaseTime 之后看门狗不工作了。后来才知道指定了 leaseTime 就是你自己管超时，Redisson 不启动看门狗。想要自动续期就别传 leaseTime。

## RedLock——争议挺大的方案

普通 Redis 分布式锁有个根本问题：主从切换可能丢锁。A 在 master 拿到锁，master 挂了还没同步到 slave，slave 升为 master，B 又能拿到锁了。

Redis 作者 antirez 提出了 RedLock：准备 N 个（建议 5 个）独立 Redis 实例，在多数实例上拿到锁才算成功。

听起来靠谱？分布式系统大佬 Martin Kleppmann 写文章怼了 RedLock，核心观点是：

1. 依赖时钟，但分布式系统里时钟不可靠（NTP 漂移、GC 停顿等）
2. 要强一致性的锁，应该用 ZooKeeper 或 etcd 这种有共识算法的
3. 只是效率优化的话，单实例 Redis 锁就够了

antirez 也写了回应，两人来回怼了一轮。我个人觉得 Martin 说得有道理。实际中也很少见有人用 RedLock，大部分场景 Redisson 单实例锁就够了。真对一致性要求极高，上 ZooKeeper。

## 小结

分布式锁的演进路线：

1. SETNX → 会死锁
2. SETNX + EXPIRE → 不原子
3. SET NX EX → 可能误删
4. SET NX EX + Lua 删除 → 可能超时
5. Redisson 看门狗 → 基本够用
6. RedLock → 有争议，慎用

日常开发直接上 Redisson。记住：别指定 leaseTime（让看门狗干活），unlock 前检查是不是当前线程的锁。

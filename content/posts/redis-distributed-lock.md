---
title: "Redis 分布式锁踩坑记"
date: 2024-04-10
categories: ["中间件"]
tags: ["Redis", "分布式", "锁"]
draft: true
---

# Redis 分布式锁踩坑记

分布式锁这个东西，面试必问，实际开发也经常用。我做课程项目的时候在这上面栽了好几个跟头，今天把踩过的坑总结一下。

## 最简单的实现：SETNX

分布式锁的核心思路很简单：大家都去抢同一个 key，谁抢到谁执行。

最原始的写法：

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

假设拿到锁之后服务器挂了，`finally` 里的 `delete` 没执行，这锁就永远不会释放——死锁。

所以得加过期时间：

```java
Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent("lock:order:" + orderId, "1", 30, TimeUnit.SECONDS);
```

注意一定要用 `SET key value EX seconds NX` 这个原子命令。千万别先 SETNX 再 EXPIRE，中间挂了还是死锁。我第一次写就犯了这个错。

但过期时间又带来新问题：业务执行时间超过锁的过期时间怎么办？锁过期了，别的线程拿到锁，两个线程同时执行，乱套了。

而且还有个更隐蔽的坑：A 的锁过期了，B 拿到锁，A 执行完去 DEL，删的其实是 B 的锁。

解决"误删"的办法是给 value 加个唯一标识（比如 UUID），删除前先检查：

```java
String requestId = UUID.randomUUID().toString();
Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent("lock:order:" + orderId, requestId, 30, TimeUnit.SECONDS);

// 释放锁时用 Lua 脚本保证原子性
String script = "if redis.call('get', KEYS[1]) == ARGV[1] then " +
                "return redis.call('del', KEYS[1]) else return 0 end";
redisTemplate.execute(new DefaultRedisScript<>(script, Long.class),
    Collections.singletonList("lock:order:" + orderId), requestId);
```

为啥用 Lua 脚本？因为 GET 和 DEL 两步不是原子的，中间可能有别的操作插进来。Lua 脚本在 Redis 里是原子执行的。

## Redisson 和看门狗机制

上面那些坑，自己处理太麻烦了。Redisson 帮你把这些都封装好了：

```java
RLock lock = redissonClient.getLock("lock:order:" + orderId);
try {
    if (lock.tryLock(5, 30, TimeUnit.SECONDS)) {
        doSomething();
    }
} finally {
    lock.unlock();
}
```

Redisson 最牛的地方是看门狗（Watchdog）机制。如果你不指定过期时间（leaseTime），Redisson 会启动一个后台线程，每隔 10 秒（默认锁超时时间 30 秒的 1/3）检查一下，如果你还持有锁就自动续期。

这就完美解决了"业务执行时间超过锁过期时间"的问题。业务没执行完，锁就一直续；业务完了或者进程挂了，看门狗也跟着没了，锁自然过期。

我在用 Redisson 的时候踩过一个坑：`tryLock` 指定了 leaseTime，结果看门狗不工作了。后来才知道，指定了 leaseTime 就意味着你自己管超时，Redisson 不会启动看门狗。想要自动续期就别传 leaseTime。

## RedLock——争议挺大的方案

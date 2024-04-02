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
SETNX lock:order:1001 "locked"    # 不存在才设置，返回1表示拿到锁
DEL lock:order:1001                # 用完删掉
```

Java 代码大概这样：

```java
Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent("lock:order:" + orderId, "1");
if (Boolean.TRUE.equals(locked)) {
    try {
        // 执行业务逻辑
        doSomething();
    } finally {
        redisTemplate.delete("lock:order:" + orderId);
    }
}
```

看起来没问题？坑大了。

## 过期时间的坑

假设拿到锁之后，服务器挂了，`finally` 里的 `delete` 没执行，这个锁就永远不会释放——死锁了。

所以得加过期时间：

```java
Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent("lock:order:" + orderId, "1", 30, TimeUnit.SECONDS);
```

注意这里一定要用 `SET key value EX seconds NX` 这个原子命令。千万别先 SETNX 再 EXPIRE，这两步之间要是挂了还是死锁。我第一次写的时候就犯了这个错，还好代码 review 的时候同学帮我指出来了。

但加了过期时间又带来新问题：如果业务执行时间超过了锁的过期时间呢？锁过期了，别的线程拿到了锁，两个线程同时在执行，这不就乱套了？

而且还有个更隐蔽的坑：A 的锁过期了，B 拿到了锁，然后 A 执行完了去 DEL，删的其实是 B 的锁。

## Redisson 和看门狗机制

## RedLock——争议挺大的方案

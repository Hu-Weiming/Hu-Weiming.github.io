---
title: "Redis 五种数据结构，各有各的妙用"
date: 2024-02-20
categories: ["中间件"]
tags: ["Redis", "缓存", "数据结构"]
draft: true
---

# Redis 五种数据结构，各有各的妙用

Redis 谁都用过吧？但我发现很多人（包括之前的我）用 Redis 就只会 `SET` 和 `GET`，把它当个 key-value 缓存用。其实 Redis 有五种基本数据结构，每种都有自己的应用场景，选对了效率翻倍，选错了可能还不如不用。

## String——最简单但别小看它

String 是 Redis 最基础的数据类型。一个 key 对应一个 value，value 最大 512MB。

常见用法：

```bash
SET user:token:1001 "abc123" EX 3600   # 存 token，1小时过期
GET user:token:1001                      # 取 token

INCR article:view:2001                   # 文章浏览量 +1
INCRBY inventory:sku:3001 -1            # 库存 -1
```

底层编码有三种：
- **int**：值是整数且小于 2^63，直接存数字
- **embstr**：字符串长度 <= 44 字节，一次内存分配
- **raw**：字符串长度 > 44 字节，两次内存分配

为啥是 44？因为 Redis 对象头 16 字节 + SDS 头 3 字节 + 末尾 \0 一共 20 字节。jemalloc 会分配 64 字节，64 - 20 = 44。这个细节面试偶尔会问。

实际项目里 String 最常用的场景就是缓存和计数器。我之前做选课系统的时候用 `INCR` 做并发计数，原子操作不用加锁，很方便。

## Hash——存对象就用它

Hash 适合存结构化数据，比如用户信息：

```bash
HSET user:1001 name "张三" age 21 major "计算机"
HGET user:1001 name        # 取单个字段
HGETALL user:1001          # 取所有字段
```

你可能会想，用 String 存 JSON 也能存对象啊，为啥要用 Hash？

区别在于：String 存 JSON 的话，改一个字段得把整个 JSON 读出来、改完再写回去。Hash 可以直接 `HSET` 改单个字段，省带宽省操作。

## List——队列和栈都能搞

## Set——去重和交并集

## ZSet——排行榜神器

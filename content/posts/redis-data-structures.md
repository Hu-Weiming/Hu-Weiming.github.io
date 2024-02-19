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

实际项目里 String 最常用的就是缓存和计数器。我之前做选课系统的时候用 `INCR` 做并发计数，原子操作不用加锁，很方便。

## Hash——存对象就用它

Hash 适合存结构化数据：

```bash
HSET user:1001 name "张三" age 21 major "计算机"
HGET user:1001 name        # 取单个字段
HGETALL user:1001          # 取所有字段
```

你可能会想，用 String 存 JSON 也能存对象啊，为啥要用 Hash？

区别在于：String 存 JSON 的话，改一个字段得整个 JSON 读出来、改完再写回去。Hash 可以直接 `HSET` 改单个字段，省带宽省操作。

底层编码：字段少且值短的时候用 ziplist（Redis 7.0 改成了 listpack），省内存。字段多了自动转成 hashtable。

有个坑：`HGETALL` 在字段特别多的时候会阻塞 Redis，因为 Redis 是单线程的。字段多的话用 `HSCAN` 分批取。

## List——队列和栈都能搞

List 底层是 quicklist，ziplist 和链表的混合体。

```bash
LPUSH queue:email "msg1" "msg2"    # 左边插入
RPOP queue:email                    # 右边弹出 → 队列
LPOP queue:email                    # 左边弹出 → 栈

BRPOP queue:email 30               # 阻塞弹出，最多等30秒
```

`BRPOP` 是做消息队列的关键。没有消息的时候客户端阻塞等待，比轮询省资源多了。

不过用 List 做消息队列有个问题：消息取出来就没了，消费者挂了消息就丢。生产环境还是用 Stream 或者 RabbitMQ/Kafka 比较靠谱。课程项目里用 List 做过简单的异步任务队列，demo 级别够用。

## Set——去重和交并集

Set 里面元素不重复，而且支持集合运算：

```bash
SADD like:article:2001 "user:1001" "user:1002"   # 点赞
SISMEMBER like:article:2001 "user:1001"            # 是否点过赞
SCARD like:article:2001                             # 点赞数

SINTER follow:1001 follow:1002                      # 共同关注
SDIFF follow:1001 follow:1002                       # 我关注ta没关注的
```

微博的共同关注、可能认识的人，底层就可以用 Set 的交集差集来算。

底层编码：元素少且都是整数时用 intset，否则用 hashtable。

## ZSet——排行榜神器

ZSet 是我觉得 Redis 最有意思的数据结构。每个元素有个 score，按 score 排序：

```bash
ZADD ranking:game 1000 "player:A" 800 "player:B" 1200 "player:C"
ZREVRANGE ranking:game 0 9 WITHSCORES    # Top 10（分数从高到低）
ZRANK ranking:game "player:B"             # 排名（从0开始）
ZINCRBY ranking:game 50 "player:B"        # 加分
```

排行榜、热搜、延迟队列，都可以用 ZSet。

底层编码：元素少时用 ziplist，多了用 skiplist（跳表）+ hashtable。跳表是个很有意思的数据结构，查找效率和平衡二叉树差不多，但实现简单得多。Redis 选跳表而不是红黑树，据说是因为 antirez 觉得跳表代码更好写好调试。

说到实际应用，我在做一个校园二手交易平台的时候，用 ZSet 做了一个"最近发布"的功能。score 用时间戳，`ZREVRANGEBYSCORE` 就能按时间倒序取，比数据库 ORDER BY 快多了。

## 选型总结

| 数据结构 | 适合场景 | 底层编码 |
|----------|----------|----------|
| String | 缓存、计数器、分布式锁 | int/embstr/raw |
| Hash | 对象属性、购物车 | ziplist/hashtable |
| List | 消息队列、最新消息列表 | quicklist |
| Set | 去重、社交关系、抽奖 | intset/hashtable |
| ZSet | 排行榜、延迟队列、热搜 | ziplist/skiplist+hashtable |

选数据结构的时候想想你的查询模式。要精确查找用 Hash，要排序用 ZSet，要去重用 Set。别什么都用 String 硬塞 JSON，那是暴殄天物。

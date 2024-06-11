---
title: "MySQL 索引优化，别再全表扫描了"
date: 2024-06-15
categories: ["数据库"]
tags: ["MySQL", "索引", "性能优化"]
draft: true
---

# MySQL 索引优化，别再全表扫描了

上学期数据库课的大作业，我写了个选课系统。数据量小的时候跑得飞快，一导入几万条测试数据就卡得不行。一查原因——全表扫描。那时候才真正意识到索引的重要性。

## B+树——索引的底层结构

MySQL 的 InnoDB 引擎用 B+树来组织索引。

![B-tree 结构示意图](https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/B-tree-definition.svg/831px-B-tree-definition.svg.png)

B+树的特点：
- 非叶子节点只存 key，不存数据
- 叶子节点存所有数据，用链表串起来
- 所有查询都要走到叶子节点，查询效率稳定

为啥不用红黑树？因为磁盘 IO 是瓶颈。B+树很矮很胖，三层就能存上千万行数据，查找一条数据最多三次磁盘 IO。

简单算一下：主键 bigint 8 字节，指针 6 字节，一个 16KB 的页能存 1170 个 key。叶子节点假设每行 1KB，一页存 16 行。三层就是 1170 × 1170 × 16 ≈ 两千万行。

## 聚簇索引 vs 非聚簇索引

**聚簇索引**（主键索引）：叶子节点直接存整行数据。InnoDB 的数据按主键顺序组织，一张表只能有一个。

**非聚簇索引**（二级索引）：叶子节点存主键值。查到主键后还要去聚簇索引查完整数据，这叫**回表**。

```sql
-- name 上有索引
SELECT * FROM student WHERE name = '张三';
-- 1. name 索引找到主键 id=1001
-- 2. 拿 id=1001 去聚簇索引查完整行 → 回表
```

回表就是两次 B+树查找，数据量大的时候开销不小。

## 最左匹配原则

联合索引的匹配规则。假设有个联合索引 `(a, b, c)`：

```sql
WHERE a = 1 AND b = 2 AND c = 3   -- ✅ 三个字段都用上
WHERE a = 1 AND b = 2              -- ✅ 用到 a, b
WHERE a = 1                        -- ✅ 用到 a
WHERE b = 2 AND c = 3              -- ❌ 没有 a，索引用不上
WHERE a = 1 AND c = 3              -- ⚠️ 只用到 a，c 用不上
```

原理很简单：联合索引在 B+树里是先按 a 排序，a 相同再按 b 排，b 相同再按 c 排。没有 a 的话 b 是无序的，当然没法用索引。

我之前犯过一个错：建了个 `(create_time, status)` 的联合索引，结果查询条件是 `WHERE status = 1`，索引完全没走上。后来改成 `(status, create_time)` 就好了。所以建联合索引的时候，区分度高的、常用的字段放前面。

还有个容易搞混的地方：`WHERE a = 1 AND b > 2 AND c = 3`，这里 a 和 b 能用到索引，但 c 用不上。因为 b 用了范围查询，后面的字段就没法走索引了。

## explain 怎么看

怎么知道查询有没有走索引？用 `EXPLAIN`。

```sql
EXPLAIN SELECT * FROM student WHERE name = '张三';
```

输出里几个关键字段：

| 字段 | 含义 |
|------|------|
| type | 访问类型，从好到坏：const > eq_ref > ref > range > index > ALL |
| key | 实际用到的索引 |
| rows | 预估扫描行数 |
| Extra | 额外信息 |

type 是 ALL 就是全表扫描，得优化。ref 表示用了索引等值查找，range 表示索引范围查找，这俩都还行。

Extra 里几个常见的值：
- `Using index`：覆盖索引，不用回表，很好
- `Using where`：用了 WHERE 过滤
- `Using filesort`：需要额外排序，尽量避免
- `Using temporary`：用了临时表，尽量避免

## 覆盖索引——少一次回表

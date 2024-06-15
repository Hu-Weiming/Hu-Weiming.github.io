---
title: "MySQL 索引优化，别再全表扫描了"
date: 2024-06-15
categories: ["数据库"]
tags: ["MySQL", "索引", "性能优化"]
draft: false
---

# MySQL 索引优化，别再全表扫描了

上学期数据库课的大作业，我写了个选课系统。数据量小的时候跑得飞快，一导入几万条测试数据就卡得不行。一查原因——全表扫描。那时候才真正意识到索引有多重要。

## B+树——索引的底层结构

MySQL 的 InnoDB 引擎用 B+树组织索引。

![B-tree 结构示意图](https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/B-tree-definition.svg/831px-B-tree-definition.svg.png)

B+树的特点：
- 非叶子节点只存 key，不存数据
- 叶子节点存所有数据，用链表串起来
- 查询都走到叶子节点，效率稳定

为啥不用红黑树？磁盘 IO 是瓶颈。B+树很矮很胖，三层就能存上千万行数据，查一条记录最多三次磁盘 IO。

算一笔账：主键 bigint 8 字节，指针 6 字节，一个 16KB 的页存约 1170 个 key。叶子节点假设每行 1KB，一页 16 行。三层就是 1170 x 1170 x 16 约两千万行。

## 聚簇索引 vs 非聚簇索引

**聚簇索引**（主键索引）：叶子节点直接存整行数据。一张表只能有一个。

**非聚簇索引**（二级索引）：叶子节点存的是主键值。查到主键后还要去聚簇索引查完整数据——**回表**。

```sql
-- name 上有索引
SELECT * FROM student WHERE name = '张三';
-- 1. name 索引树找到主键 id=1001
-- 2. 拿 id=1001 去聚簇索引查整行 → 回表
```

回表就是两次 B+树查找，数据量大时开销不小。

## 最左匹配原则

联合索引 `(a, b, c)` 的匹配规则：

```sql
WHERE a = 1 AND b = 2 AND c = 3   -- ✅ 都用上了
WHERE a = 1 AND b = 2              -- ✅ 用到 a, b
WHERE a = 1                        -- ✅ 用到 a
WHERE b = 2 AND c = 3              -- ❌ 没 a，用不上
WHERE a = 1 AND c = 3              -- ⚠️ 只用到 a
```

原理也不难理解：联合索引的 B+树先按 a 排序，a 相同按 b 排，b 相同按 c 排。没有 a 的话 b 就是无序的，没法走索引。

我之前建了个 `(create_time, status)` 的联合索引，查询条件是 `WHERE status = 1`，索引完全没走上。改成 `(status, create_time)` 就好了。建联合索引的时候，常查的、区分度高的字段放前面。

还有一点：`WHERE a = 1 AND b > 2 AND c = 3`，a 和 b 能用索引，但 c 用不上。范围查询后面的字段走不了索引。

## explain 怎么看

查询走没走索引，用 `EXPLAIN`：

```sql
EXPLAIN SELECT * FROM student WHERE name = '张三';
```

几个关键字段：

| 字段 | 含义 |
|------|------|
| type | 访问类型，从好到坏：const > eq_ref > ref > range > index > ALL |
| key | 实际用的索引 |
| rows | 预估扫描行数 |
| Extra | 额外信息 |

type 是 ALL 就是全表扫描，得优化。ref 是等值查找，range 是范围查找，都还行。

Extra 常见值：
- `Using index`：覆盖索引，不回表
- `Using where`：用了 WHERE 过滤
- `Using filesort`：额外排序，尽量避免
- `Using temporary`：临时表，尽量避免

我有个习惯：写完 SQL 就顺手 EXPLAIN 一下，花不了几秒钟，能提前发现很多问题。

## 覆盖索引——少一次回表

查询需要的字段全在索引里，就不用回表了：

```sql
-- 假设有联合索引 (name, age)
SELECT name, age FROM student WHERE name = '张三';
-- 索引里有 name 和 age，不用回表

SELECT * FROM student WHERE name = '张三';
-- 需要所有字段，得回表
```

所以别动不动 `SELECT *`。只查需要的字段，配合联合索引，能省不少开销。

我之前有个查询从 `SELECT *` 改成 `SELECT id, name, status`，加了个 `(name, status)` 的索引，查询时间从 200ms 降到 5ms。效果立竿见影。

## 几个优化小建议

1. **主键用自增 ID**：顺序插入避免页分裂，UUID 做主键写入性能差很多
2. **字符串字段考虑前缀索引**：`ALTER TABLE t ADD INDEX idx_name(name(10))`，只索引前 10 个字符
3. **避免索引失效的写法**：
   - 索引字段做函数操作：`WHERE YEAR(create_time) = 2024` → 改成范围查询
   - 隐式类型转换：字段是 varchar 条件写成 `WHERE phone = 13800138000` → 加引号
   - LIKE 以 % 开头：`WHERE name LIKE '%三'` → 索引用不上
4. **别建太多索引**：每个索引都是一棵 B+树，占空间，增删改都要维护

## 小结

索引优化说白了就两件事：让查询走上索引，减少回表次数。EXPLAIN 是你最好的工具，写完 SQL 就跑一下。搞清楚这些原则，日常开发基本够用了。

---
title: "MySQL 事务和 MVCC，面试必问"
date: 2024-08-20
categories: ["数据库"]
tags: ["MySQL", "事务", "MVCC"]
draft: true
---

# MySQL 事务和 MVCC，面试必问

事务和 MVCC 是 MySQL 面试里出场率最高的话题，没有之一。我准备秋招的时候翻来覆去看了好几遍，现在总算能说清楚了。

## ACID 四大特性

事务的四个特性，关键是理解怎么实现的：

- **A（原子性）**：要么全做要么全不做。靠 undo log，出错就回滚。
- **C（一致性）**：数据从一个合法状态到另一个合法状态。这是目标，靠其他三个保证。
- **I（隔离性）**：并发事务互不干扰。靠 MVCC + 锁。
- **D（持久性）**：提交后数据不丢。靠 redo log。

面试光背定义没意思，面试官想听实现原理。比如为啥用 redo log？因为直接刷数据页是随机 IO，写 redo log 是顺序 IO，快得多。先写日志，宕机了根据 redo log 恢复。这叫 WAL（Write-Ahead Logging）。

## 四种隔离级别

| 隔离级别 | 脏读 | 不可重复读 | 幻读 |
|----------|------|------------|------|
| Read Uncommitted | 可能 | 可能 | 可能 |
| Read Committed (RC) | 不可能 | 可能 | 可能 |
| Repeatable Read (RR) | 不可能 | 不可能 | 可能 |
| Serializable | 不可能 | 不可能 | 不可能 |

InnoDB 默认 **Repeatable Read**。有意思的是，InnoDB 的 RR 很大程度上也解决了幻读（通过 MVCC + 间隙锁）。

## 脏读、不可重复读、幻读

用例子说最清楚。

**脏读**：读到了别的事务还没提交的数据。

```
事务A: UPDATE account SET balance = 200 WHERE id = 1;  (未提交)
事务B: SELECT balance FROM account WHERE id = 1;  → 读到200
事务A: ROLLBACK;
// 事务B读到的200是假的
```

**不可重复读**：同一个事务里两次读同一条数据，结果不一样。

```
事务B: SELECT balance FROM account WHERE id = 1;  → 100
事务A: UPDATE balance = 200 WHERE id = 1; COMMIT;
事务B: SELECT balance FROM account WHERE id = 1;  → 200
```

**幻读**：同一个事务里两次范围查询，行数不一样。

```
事务B: SELECT * FROM account WHERE balance > 100;  → 3行
事务A: INSERT INTO account VALUES(4, 500); COMMIT;
事务B: SELECT * FROM account WHERE balance > 100;  → 4行
```

脏读和不可重复读针对"同一行"，幻读针对"行数变化"。

## MVCC 实现原理：undo log + ReadView

MVCC（多版本并发控制）是 InnoDB 实现 RC 和 RR 的核心。每行数据不只有一个版本，而是有一条版本链。

InnoDB 的每行记录有两个隐藏字段：
- `trx_id`：最后修改这行的事务 ID
- `roll_pointer`：指向 undo log 里这行的上一个版本

每次修改一行数据，旧版本会写到 undo log 里，通过 roll_pointer 串成一条链。

```
当前数据: {name: "张三", trx_id: 300, roll_pointer → }
                                                ↓
undo log: {name: "李四", trx_id: 200, roll_pointer → }
                                                ↓
undo log: {name: "王五", trx_id: 100, roll_pointer → NULL}
```

有了版本链，关键问题是：当前事务应该看哪个版本？这就是 ReadView 要解决的。

**ReadView** 是事务在执行快照读（普通 SELECT）时生成的一个"视图"，包含四个信息：

- `creator_trx_id`：当前事务的 ID
- `m_ids`：生成 ReadView 时所有活跃（未提交）事务的 ID 列表
- `min_trx_id`：活跃事务中最小的 ID
- `max_trx_id`：下一个要分配的事务 ID（当前最大事务 ID + 1）

判断规则：

1. `trx_id == creator_trx_id` → 自己改的，看得到
2. `trx_id < min_trx_id` → 这个版本在 ReadView 之前就提交了，看得到
3. `trx_id >= max_trx_id` → 这个版本在 ReadView 之后才出现，看不到
4. `min_trx_id <= trx_id < max_trx_id` → 看 trx_id 在不在 m_ids 里。在的话说明还没提交，看不到；不在的话说明已经提交了，看得到

如果当前版本看不到，就顺着 roll_pointer 往下找，直到找到一个能看到的版本。

**RC 和 RR 的区别就在于 ReadView 的生成时机：**

- **RC**：每次 SELECT 都生成新的 ReadView。所以能看到其他事务新提交的数据。
- **RR**：只在事务第一次 SELECT 时生成 ReadView，后续复用。所以看到的一直是同一个快照。

就这一个区别，导致了 RC 有不可重复读问题而 RR 没有。我觉得这是 MVCC 最精妙的地方。

说到这里我想起之前 debug 的一个问题。同事在 RR 级别下开了个事务，先 SELECT 了一下，然后过了一段时间再 SELECT，发现数据"没变化"。他以为是缓存的问题，折腾了半天才意识到是 MVCC——第一次 SELECT 生成了 ReadView，之后的 SELECT 都用这个 ReadView，当然看不到其他事务提交的修改。

## 快照读 vs 当前读

顺便提一下这两个概念：

- **快照读**：普通的 `SELECT`，走 MVCC，读的是历史版本
- **当前读**：`SELECT ... FOR UPDATE`、`SELECT ... LOCK IN SHARE MODE`、`INSERT`、`UPDATE`、`DELETE`，读的是最新数据，会加锁

RR 级别下，快照读通过 MVCC 解决了不可重复读和幻读。但当前读呢？当前读是通过**临键锁**（Next-Key Lock = 行锁 + 间隙锁）来防止幻读的。

## 小结

事务和 MVCC 这块内容不少，但核心就几个点：ACID 靠什么实现、ReadView 的判断规则、RC 和 RR 的 ReadView 生成时机区别。把这些理清楚了，面试基本能应对。建议自己在 MySQL 里开两个终端模拟一下并发场景，实操一遍比看十遍博客管用。

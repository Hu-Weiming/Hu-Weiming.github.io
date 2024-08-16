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
- **D（��久性）**：提交后数据不丢。靠 redo log。

面试的时候光背定义没意思，面试官想听实现原理。比如为啥用 redo log？因为直接刷数据页是随机 IO，写 redo log 是顺序 IO，快得多。先写日志，宕机了重启根据 redo log ���复。

## 四种隔离级别

| ���离级别 | 脏读 | 不可重复读 | 幻读 |
|----------|------|------------|------|
| Read Uncommitted | 可能 | 可能 | 可能 |
| Read Committed (RC) | 不可能 | 可能 | 可能 |
| Repeatable Read (RR) | 不可能 | 不可能 | 可能 |
| Serializable | 不可能 | 不可能 | 不可能 |

InnoDB 默认 **Repeatable Read**。有意思的是，InnoDB 的 RR 很大程度上也解决了幻读（MVCC + 间隙锁）。

## 脏读、不可重复读、幻读

这三兄弟面试必问，用例子说最清楚。

**脏读**：读到了别的事务还没提交的数据。万一那个事务回滚了呢？你读到的就是脏数据。

```
事务A: UPDATE account SET balance = 200 WHERE id = 1;  (未提交)
事务B: SELECT balance FROM account WHERE id = 1;  → 读到200
事务A: ROLLBACK;
// 事务B读到的200是错的
```

**不可重复读**：同一个事务里，两次读同一条数据结果不一样。因为中间有别的事务改了这条数据并提交了。

```
事务B: SELECT balance FROM account WHERE id = 1;  → 100
事务A: UPDATE account SET balance = 200 WHERE id = 1; COMMIT;
事务B: SELECT balance FROM account WHERE id = 1;  → 200（变了！）
```

**幻读**：同一个事务里，两次范围查询结果行数不一样。因为别的事务插入了新行。

```
事务B: SELECT * FROM account WHERE balance > 100;  → 3行
事务A: INSERT INTO account VALUES(4, 500); COMMIT;
事务B: SELECT * FROM account WHERE balance > 100;  → 4行（多了一行！）
```

脏读和不可重复读针对的是"同一行数据"，幻读针对的是"行数变化"。这个区分搞清楚了，面试的时候才能说明白。

## MVCC 实��原理：undo log + ReadView

MVCC（多版本并发控制）是 InnoDB 实现 RC 和 RR 隔离级别的核心机制。看名字就知道——多版本。每行数据不是只有一个版本，而是有一条版本链。

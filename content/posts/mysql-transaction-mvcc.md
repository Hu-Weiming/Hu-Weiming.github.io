---
title: "MySQL 事务和 MVCC，面试必问"
date: 2024-08-20
categories: ["数据库"]
tags: ["MySQL", "事务", "MVCC"]
draft: true
---

# MySQL 事务和 MVCC，面试必问

事务和 MVCC 是 MySQL 面试里出场率最高的话题了，没有之一。我准备秋招的时候把这块儿翻来覆去看了好几遍，现在总算能说清楚了。

## ACID 四大特性

事务的四个特性，背是能背下来，关键是理解怎么实现的。

- **A（原子性）**：事务要么全做要么全不做。靠 undo log 实现，出错了就回滚。
- **C（一致性）**：数据从一个合法状态转到另一个合法状态。这个其实是目标，靠其他三个来保证。
- **I（隔离性）**：多个事务并发执行互不干扰。靠 MVCC + 锁实现。
- **D（持久性）**：事务提交后数据不会丢。靠 redo log 实现，先写日志再刷盘。

其实吧，面试的时候光说出 ACID 的定义没啥意思，面试官想听的是你对实现原理的理解。比如为啥用 redo log 保证持久性？因为直接刷数据页是随机 IO，写 redo log 是顺序 IO，快得多。先写 redo log，即使宕机了，重启后根据 redo log 恢复就行。

## 四种隔离级别

SQL 标准定义了四种隔离级别：

| 隔离级别 | 脏读 | 不可重复读 | 幻读 |
|----------|------|------------|------|
| Read Uncommitted | 可能 | 可能 | 可能 |
| Read Committed (RC) | 不可能 | 可能 | 可能 |
| Repeatable Read (RR) | 不可能 | 不可能 | 可能 |
| Serializable | 不可能 | 不可能 | 不可能 |

MySQL 的 InnoDB 默认是 **Repeatable Read**。但有意思的是，InnoDB 的 RR 在很大程度上也解决了幻读问题（通过 MVCC + 间隙锁）。

Oracle 默认是 Read Committed，所以很多从 Oracle 转到 MySQL 的公司会把 MySQL 的隔离级别也改成 RC。阿里就是这样的，他们内部规范就是用 RC。

## 脏读、不可重复读、幻读

## MVCC 实现原理：undo log + ReadView

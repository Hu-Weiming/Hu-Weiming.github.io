---
title: "ConcurrentHashMap 到底怎么保证线程安全的"
date: 2022-11-20
categories: ["Java基础"]
tags: ["Java", "并发", "集合框架"]
draft: true
---

# ConcurrentHashMap 到底怎么保证线程安全的

上篇写了 HashMap，有同学私信问我 ConcurrentHashMap 和 HashMap 有什么区别。其实吧，区别大了去了，JDK8 的 ConcurrentHashMap 基本是重写的，跟 JDK7 完全不是一个思路。

我花了差不多一周才把源码理清楚，这篇就来聊聊它到底怎么在并发场景下保证线程安全。

## JDK7 的 Segment 分段锁

先说 JDK7 的方案，因为面试还是会问到。

JDK7 的 ConcurrentHashMap 内部有一个 `Segment` 数组，每个 Segment 继承了 `ReentrantLock`，里面维护一个 HashEntry 数组。

简单说就是把整个 Map 分成了好几段，每段有自己的锁。你要操作某个 key，先定位到对应的 Segment，再锁那个 Segment。不同 Segment 之间互不影响，所以可以并发操作。

默认有 16 个 Segment，理论上最多支持 16 个线程同时写入。

这个设计虽然比给整个 Map 加一把锁好很多，但还是有局限性：Segment 的个数初始化之后就不能变了，而且结构比较复杂。

## JDK8 彻底重写了

## CAS + synchronized 怎么配合的

## 并发扩容是怎么做的

## 和 Hashtable 比一下

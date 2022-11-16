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

JDK8 的 ConcurrentHashMap 抛弃了 Segment，结构改成跟 HashMap 一样的 `Node<K,V>[]` 数组。那线程安全怎么保证？用的是 CAS + synchronized，粒度细到了每个桶（数组的每个位置）。

核心数据结构：

```java
transient volatile Node<K,V>[] table;
```

注意这里的 `volatile`。table 引用本身是 volatile 的，保证扩容时新数组对其他线程可见。而每个 Node 的 val 和 next 也是 volatile 的，保证读操作不需要加锁。

说到这里你应该能感觉到，JDK8 的方案比 JDK7 灵活多了。锁的粒度从 Segment（一段）缩小到了单个桶。

## CAS + synchronized 怎么配合的

看 `putVal` 的源码，主要分这几种情况：

**情况一：桶是空的。** 用 CAS 操作直接把新节点放进去，不需要加锁。

```java
else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
    if (casTabAt(tab, i, null, new Node<K,V>(hash, key, value)))
        break;
}
```

CAS 失败说明有别的线程抢先放了，那就进入下一轮循环再看看情况。

**情况二：正在扩容。** 当前线程会帮忙一起扩容（后面单独讲）。

**情况三：桶不为空，也没在扩容。** 用 synchronized 锁住这个桶的头节点，然后遍历链表或红黑树进行插入。

```java
synchronized (f) {
    // 在这里操作链表或红黑树
}
```

为什么空桶用 CAS，非空桶用 synchronized？空桶只需要一次原子操作，CAS 又快又轻。非空桶要遍历链表，操作比较复杂，CAS 搞不定，老老实实加锁。

这种组合还挺巧妙的。

## 并发扩容是怎么做的

这个是 ConcurrentHashMap 最骚的地方。HashMap 扩容是单线程的，ConcurrentHashMap 支持多线程一起扩容。

## 和 Hashtable 比一下

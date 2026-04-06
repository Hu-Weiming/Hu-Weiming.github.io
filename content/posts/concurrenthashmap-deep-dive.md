---
title: "ConcurrentHashMap 线程安全原理"
date: 2022-11-20
categories: ["Java基础"]
tags: ["Java", "并发", "集合框架"]
draft: false
---

# ConcurrentHashMap 到底怎么保证线程安全的

上篇写了 HashMap，有同学私信问我 ConcurrentHashMap 和 HashMap 有什么区别。其实吧，区别大了去了，JDK8 的 ConcurrentHashMap 基本是重写的，跟 JDK7 完全两个思路。

花了差不多一周把源码理清楚，这篇来聊聊它到底怎么在并发场景下保证线程安全。

## JDK7 的 Segment 分段锁

先说 JDK7 的方案，面试还是会问。

JDK7 的 ConcurrentHashMap 内部有一个 `Segment` 数组，每个 Segment 继承了 `ReentrantLock`，里面维护一个 HashEntry 数组。

简单说就是把整个 Map 分成好几段，每段有自己的锁。操作某个 key 时，先定位到它所在的 Segment，再锁那个 Segment。不同 Segment 之间互不影响，可以并发操作。

默认 16 个 Segment，理论上最多 16 个线程同时写入。

这个设计比给整个 Map 加一把大锁好很多，但也有局限——Segment 个数初始化之后就固定了，而且结构比较复杂。

## JDK8 彻底重写了

JDK8 抛弃了 Segment，结构改成跟 HashMap 一样的 `Node<K,V>[]` 数组。线程安全靠 CAS + synchronized，粒度细到了每个桶。

```java
transient volatile Node<K,V>[] table;
```

注意 `volatile`。table 引用是 volatile 的，保证扩容时新数组对其他线程可见。每个 Node 的 val 和 next 也是 volatile 的，保证读操作不需要加锁。

锁的粒度从 Segment（一段）缩小到了单个桶，灵活太多了。

## CAS + synchronized 怎么配合的

看 `putVal` 的源码，分几种情况：

**桶是空的**——用 CAS 直接放新节点，不加锁。

```java
else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
    if (casTabAt(tab, i, null, new Node<K,V>(hash, key, value)))
        break;
}
```

CAS 失败说明别的线程抢先了，进入下一轮循环重试。

**正在扩容**——当前线程会帮忙一起搬数据（后面讲）。

**桶不为空，没在扩容**——用 synchronized 锁住头节点，遍历链表或红黑树做插入。

```java
synchronized (f) {
    // 操作链表或红黑树
}
```

为什么空桶用 CAS，非空桶用 synchronized？空桶只需要一次原子写入，CAS 快且轻量。非空桶要遍历链表，操作复杂，CAS 搞不定，老老实实加锁更靠谱。

顺便说一下，JDK8 的 synchronized 已经优化了很多（偏向锁、轻量级锁），性能不比 ReentrantLock 差。Doug Lea 选 synchronized 而不是显式锁，也是考虑到了这一点。

## 并发扩容是怎么做的

这个是 ConcurrentHashMap 最妙的设计。HashMap 扩容是单线程干，ConcurrentHashMap 可以多线程一起搬。

大致流程：

1. 某个线程发现需要扩容，创建一个 2 倍大小的新数组 `nextTable`。
2. 把旧数组分成多段，每个线程认领一段来搬。每段最少 16 个桶。
3. 某个桶搬完之后，在旧数组对应位置放一个 `ForwardingNode`。其他线程看到它就知道"这个桶搬完了"。
4. 其他线程要 put 时发现正在扩容，它也会加入搬运，这就是 `helpTransfer`。

想想看，数组有 1024 个桶，一个线程搬多慢。让大家一起搬，速度快得多。

我觉得这个设计理念特别好：不是让线程干等着，而是把等待的时间利用起来帮忙干活。

## 和 Hashtable 比一下

面试经常问"为什么不用 Hashtable"。Hashtable 方案简单粗暴，给每个方法加 synchronized：

```java
public synchronized V get(Object key) { ... }
public synchronized V put(K key, V value) { ... }
```

任何时候只能有一个线程操作 Map，读也加锁，写也加锁，并发性能可想而知。

ConcurrentHashMap 的读操作基本不加锁（靠 volatile），写操作只锁一个桶。差距非常明显。

话说回来，`Collections.synchronizedMap()` 也一样，本质上就是一把大锁包住所有操作，高并发场景别用。

## 小结

JDK7 到 JDK8，ConcurrentHashMap 从分段锁变成了 CAS + synchronized + 并发扩容，设计上精进了很多。面试问并发集合基本必考这块，把上面这些理清楚应该够用了。

说实话这块源码比 HashMap 难读很多。建议先搞懂 HashMap 再来看 ConcurrentHashMap，不然容易直接劝退。

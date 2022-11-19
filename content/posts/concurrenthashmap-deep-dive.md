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

简单说就是把整个 Map 分成好几段，每段有自己的锁。你要操作某个 key，先定位到它所在的 Segment，再锁那个 Segment。不同 Segment 之间互不影响，可以并发操作。

默认有 16 个 Segment，理论上最多支持 16 个线程同时写入。

这个设计比给整个 Map 加一把大锁好很多，但还是有局限——Segment 个数初始化之后就固定了，而且结构比较复杂。

## JDK8 彻底重写了

JDK8 的 ConcurrentHashMap 抛弃了 Segment，结构改成跟 HashMap 一样的 `Node<K,V>[]` 数组。线程安全靠 CAS + synchronized，粒度细到了每个桶。

核心数据结构：

```java
transient volatile Node<K,V>[] table;
```

注意 `volatile`。table 引用本身是 volatile 的，保证扩容时新数组对其他线程可见。每个 Node 的 val 和 next 也是 volatile 的，保证读操作不需要加锁。

锁的粒度从 Segment（一段）缩小到了单个桶，灵活多了。

## CAS + synchronized 怎么配合的

看 `putVal` 的源码，分几种情况：

**情况一：桶是空的。** 用 CAS 直接把新节点放进去，不加锁。

```java
else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
    if (casTabAt(tab, i, null, new Node<K,V>(hash, key, value)))
        break;
}
```

CAS 失败说明别的线程抢先了，进入下一轮循环重试。

**情况二：正在扩容。** 当前线程会帮忙一起搬数据。

**情况三：桶不为空，没在扩容。** 用 synchronized 锁住头节点，遍历链表或红黑树做插入。

```java
synchronized (f) {
    // 在这里操作链表或红黑树
}
```

为什么空桶用 CAS，非空桶用 synchronized？空桶只需要一次原子写入，CAS 又快又轻量。非空桶要遍历链表，操作复杂，CAS 搞不定，老老实实加锁更靠谱。

顺便说一下，JDK8 里 synchronized 已经做了很多优化（偏向锁、轻量级锁），性能不比 ReentrantLock 差，所以 Doug Lea 选了 synchronized 而不是显式锁。

## 并发扩容是怎么做的

这个是 ConcurrentHashMap 最妙的地方。HashMap 扩容是单线程的，但 ConcurrentHashMap 支持多线程一起搬。

大致流程：

1. 某个线程发现需要扩容，创建一个 2 倍大小的新数组 `nextTable`。
2. 把旧数组分成多段，每个线程负责搬一段。每段的最小长度是 16。
3. 某个桶搬完之后，在旧数组的对应位置放一个 `ForwardingNode`。其他线程看到这个节点就知道"这个桶已经搬过了"。
4. 如果其他线程要 put 但发现正在扩容，它也会加入搬运行列。这就是 `helpTransfer`。

你想想，如果数组有 1024 个桶，一个线程搬是不是很慢？让大家一起搬，速度快多了。

我觉得这个设计理念特别好：不是阻塞等待，而是让干等的线程也来帮忙。

## 和 Hashtable 比一下

有时候面试会问"为什么不用 Hashtable"。Hashtable 的方案简单粗暴——给每个方法都加 synchronized：

```java
public synchronized V get(Object key) { ... }
public synchronized V put(K key, V value) { ... }
```

这意味着任何时候只能有一个线程操作这个 Map。读也要锁，写也要锁，并发性能可想而知。

ConcurrentHashMap 的读操作基本不加锁（靠 volatile 保证可见性），写操作只锁一个桶。差距很明显。

话说回来，还有人会问 `Collections.synchronizedMap()` 行不行。本质上跟 Hashtable 一样，就是给每个操作加了一把大锁，不推荐在高并发场景用。

## 小结

JDK7 到 JDK8，ConcurrentHashMap 从分段锁变成了 CAS + synchronized + 并发扩容，设计上精进了很多。面试基本上问到并发必考这块，把上面这些理清楚应该够用了。

不过说实话，这块源码确实比 HashMap 难读很多。我建议先搞懂 HashMap，再看 ConcurrentHashMap，不然很容易懵。

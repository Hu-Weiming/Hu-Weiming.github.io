---
title: "HashMap 源码我读了三遍才看懂"
date: 2022-09-15
categories: ["Java基础"]
tags: ["Java", "集合框架", "源码"]
draft: false
---

# HashMap 源码我读了三遍才看懂

大二下学期面试实习的时候，面试官问我 HashMap 的底层原理，我支支吾吾说了个"数组加链表"就说不下去了。回来之后就下定决心要把源码读一遍。结果读了三遍才算真正搞明白，这玩意比我想象的要精妙得多。

![Hash Table 示意图](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Hash_table_5_0_1_1_1_1_0_SP.svg/380px-Hash_table_5_0_1_1_1_1_0_SP.svg.png)

## 先说说 HashMap 的内部结构

你打开 HashMap 的源码，会看到一个叫 `Node<K,V>[] table` 的数组。这就是 HashMap 的骨架。

每个 Node 长这样：

```java
static class Node<K,V> implements Map.Entry<K,V> {
    final int hash;
    final K key;
    V value;
    Node<K,V> next;  // 看到没，链表结构
}
```

本质就是：一个数组，数组的每个位置可以挂一条链表。你 put 一个 key-value 进去，先算 key 的 hash 值，定位到数组的某个下标，然后挂到那个位置的链表上。

JDK8 加了个重要改动：当链表长度超过 8 的时候，链表会转成红黑树。为啥呢？链表查找是 O(n)，红黑树是 O(log n)，hash 冲突严重的时候性能差距很大。

你可能会问，为什么阈值是 8？源码注释里写了，按泊松分布计算，链表长度达到 8 的概率大概是千万分之六。正常使用根本不会触发，这纯粹是个保底策略。

## put 一个元素到底经历了什么

来看 `putVal` 方法的核心逻辑，我把它拆开讲：

1. 算 hash。不是直接用 `key.hashCode()`，而是做了个扰动：`(h = key.hashCode()) ^ (h >>> 16)`。高 16 位和低 16 位异或一下，让 hash 分布更均匀。
2. 定位下标。用 `(n - 1) & hash` 算出数组下标，n 是数组长度，后面会讲为啥要是 2 的幂。
3. 如果那个位置是空的，直接放进去。
4. 如果有东西，看 key 是不是一样的，一样就覆盖 value。
5. 不一样的话，看当前节点是不是 TreeNode（红黑树节点），是的话走红黑树的插入逻辑。
6. 不是树节点就遍历链表，找到末尾插入。插入之后看链表长度有没有到 8，到了就转红黑树。

我之前踩过一个坑：以为 HashMap 的链表是头插法，结果 debug 了半天发现 JDK8 改成尾插法了。JDK7 确实是头插的，但头插法在多线程 resize 的时候会形成环链表，导致死循环。这个 bug 挺经典的，面试也爱问。

```java
// JDK8 尾插法的关键代码
for (int binCount = 0; ; ++binCount) {
    if ((e = p.next) == null) {
        p.next = newNode(hash, key, value, null);
        if (binCount >= TREEIFY_THRESHOLD - 1)
            treeifyBin(tab, hash);
        break;
    }
    // ...
}
```

## 扩容机制 resize

当元素数量超过 `capacity * loadFactor`（默认 16 * 0.75 = 12）的时候，就会触发扩容。扩容就是把数组长度翻倍，然后重新分配所有元素的位置。

这里有个很巧妙的设计。扩容之后，每个元素要么留在原来的位置，要么移动到"原位置 + 旧容量"的位置。不需要重新算 hash。

假设旧容量是 16（二进制 10000），新容量 32（二进制 100000）。原来用 `hash & 01111` 算下标，现在用 `hash & 11111`。就多看了一个 bit，那个 bit 是 0 就留在原地，是 1 就移到新位置。

所以源码里只需要 `(e.hash & oldCap) == 0` 这一个判断就搞定了。这种位运算技巧真的很优雅。

顺便提一下，扩容是个挺重的操作，所有元素都要重新分配。如果你事先知道要放多少元素，用 `new HashMap<>(expectedSize)` 指定初始容量，能避免好几次扩容。阿里巴巴开发规约也是这么推荐的。

## 为什么容量一定要是 2 的幂次

这个问题面试高频出现，原因有两个：

**第一**，定位数组下标用的是 `(n - 1) & hash`，而不是 `hash % n`。当 n 是 2 的幂的时候这两个等价，但位运算比取模快得多。

**第二**，扩容的时候可以用上面说的那个技巧，只看多出来的那一位是 0 还是 1。如果容量不是 2 的幂，这个优化就没法做。

你可能会想：那我 `new HashMap<>(7)` 会怎样？HashMap 会自动帮你找到大于等于 7 的最小 2 次幂，也就是 8。看这段代码：

```java
static final int tableSizeFor(int cap) {
    int n = cap - 1;
    n |= n >>> 1;
    n |= n >>> 2;
    n |= n >>> 4;
    n |= n >>> 8;
    n |= n >>> 16;
    return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
}
```

效果就是把最高位的 1 后面所有位都变成 1，再加 1，得到最近的 2 次幂。看着费解，但思路其实很简单。

## 几个面试爱问的小问题

**HashMap 线程安全吗？** 不安全。多线程同时 put 可能丢数据，JDK7 还可能死循环。要线程安全就用 ConcurrentHashMap。

**key 可以是 null 吗？** 可以，null 的 hash 是 0，固定放在数组下标 0 的位置。

**为什么重写 equals 必须重写 hashCode？** 因为 HashMap 先用 hashCode 定位桶，再用 equals 比较 key。如果两个对象 equals 返回 true 但 hashCode 不同，HashMap 会把它们放到不同的桶里，get 的时候就找不到了。我之前拿自定义对象做 key 的时候踩过这个坑，get 出来一直是 null，debug 了好久才发现。

## 最后说两句

HashMap 的源码其实不算长，核心方法就 putVal、getNode、resize 几个。但里面的设计思路真的值得品味——位运算的使用、红黑树的引入、扩容的优化，每个细节都有道理。

建议自己打开 IDE 跟着 debug 一遍，比看任何博客都有用。

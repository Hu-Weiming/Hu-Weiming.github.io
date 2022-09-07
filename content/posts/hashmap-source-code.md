---
title: "HashMap 源码我读了三遍才看懂"
date: 2022-09-15
categories: ["Java基础"]
tags: ["Java", "集合框架", "源码"]
draft: true
---

# HashMap 源码我读了三遍才看懂

大二下学期面试实习的时候，面试官问我 HashMap 的底层原理，我支支吾吾说了个"数组加链表"就说不下去了。回来之后我就下定决心要把源码读一遍。然后读了三遍才算真正搞明白，这玩意比我想象的要精妙得多。

![Hash Table 示意图](https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Hash_table_5_0_1_1_1_1_0_SP.svg/380px-Hash_table_5_0_1_1_1_1_0_SP.svg.png)

## 先说说 HashMap 的内部结构

你打开 HashMap 的源码，会看到一个叫 `Node<K,V>[] table` 的数组。这就是 HashMap 的骨架——一个 Node 类型的数组。

每个 Node 长这样：

```java
static class Node<K,V> implements Map.Entry<K,V> {
    final int hash;
    final K key;
    V value;
    Node<K,V> next;  // 看到没，链表结构
}
```

所以本质就是：一个数组，数组的每个位置可以挂一条链表。你 put 一个 key-value 进去，先算 key 的 hash，定位到数组的某个下标，然后挂到那个位置的链表上。

但是 JDK8 加了个大改动：当链表长度超过 8 的时候，会把链表转成红黑树。为啥呢？链表查找是 O(n)，红黑树是 O(log n)，hash 冲突严重的时候性能差距很大。

说到这里你可能会问，为什么是 8？其实源码注释里写了，按泊松分布算，链表长度达到 8 的概率已经非常非常低了（大概千万分之六）。正常使用根本不会触发，这纯粹是个保底策略。

## put 一个元素到底经历了什么

## 扩容机制 resize

## 为什么容量一定要是 2 的幂次

## 总结

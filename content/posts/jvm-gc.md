---
title: "JVM 垃圾回收看这篇就够了"
date: 2023-05-08
categories: ["Java基础"]
tags: ["Java", "JVM", "GC"]
draft: true
---

# JVM 垃圾回收看这篇就够了

JVM 垃圾回收是面试八股文里的重头戏，也是我觉得最难啃的一块。概念多、算法多、收集器也多，第一次看的时候感觉脑子不够用。这篇把我学到的整理一下，争取讲清楚。

![垃圾回收示意图](https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Tracing-garbage-collection.svg/400px-Tracing-garbage-collection.svg.png)

## 堆内存长什么样

JVM 的堆内存分成两块大区域：新生代（Young Generation）和老年代（Old Generation）。

新生代又分成三块：Eden 区和两个 Survivor 区（S0、S1）。默认比例是 8:1:1。

为什么这么分？因为研究发现大部分对象都是"朝生夕死"的，活不过一次 GC。把它们放在新生代，用比较快的算法回收。少数活得久的对象晋升到老年代，减少回收频率。

对象一般在 Eden 区创建。Eden 满了触发 Minor GC，活下来的对象搬到 Survivor 区。每熬过一次 GC，对象的年龄加 1，到了阈值（默认 15）就晋升到老年代。

## 怎么判断对象该不该回收

## 三种回收算法

## CMS 和 G1 怎么选

## 实际调优碰到的事

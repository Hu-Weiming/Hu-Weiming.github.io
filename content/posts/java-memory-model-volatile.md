---
title: "volatile 到底能保证什么"
date: 2023-07-20
categories: ["Java基础"]
tags: ["Java", "JMM", "并发"]
draft: true
---

# volatile 到底能保证什么

## Java 内存模型简单说

聊 volatile 之前，得先说说 Java 内存模型（JMM）。放心，不会讲太深，够理解 volatile 就行。

JMM 规定了线程和内存之间的关系。简单理解：每个线程有自己的工作内存（你可以想象成 CPU 缓存），线程操作变量的时候不是直接改主内存，而是先从主内存拷一份到工作内存，改完再写回去。

这就埋下了隐患——线程 A 改了变量，线程 B 可能看不到，因为 B 还在用自己工作内存里的旧值。

```
主内存:  x = 0
线程A工作内存: x = 0  →  x = 1  →  写回主内存
线程B工作内存: x = 0  →  还是0！没刷新！
```

这就是可见性问题。

## 可见性问题

来看个经典例子：

```java
public class VisibilityDemo {
    private static boolean flag = true;
    
    public static void main(String[] args) throws InterruptedException {
        new Thread(() -> {
            while (flag) {
                // 忙等待
            }
            System.out.println("线程退出");
        }).start();
        
        Thread.sleep(1000);
        flag = false;
        System.out.println("已设置 flag = false");
    }
}
```

你觉得子线程能退出吗？答案是：不一定。JIT 编译器可能把 `while(flag)` 优化成 `while(true)`，因为它发现这个线程里没人改 flag。

我当时学并发的时候写了这个 demo，在本地跑真的不会退出，挺震撼的。加上 volatile 就好了：

```java
private static volatile boolean flag = true;
```

## 有序性和指令重排

TODO

## happens-before 规则

TODO

## volatile 的底层实现：内存屏障

TODO

## DCL 单例中的 volatile

TODO

## volatile 不能保证原子性

TODO

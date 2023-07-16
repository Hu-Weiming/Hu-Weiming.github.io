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

volatile 保证了可见性：一个线程修改了变量，其他线程能立刻看到最新值。

## 有序性和指令重排

Java 编译器和处理器为了优化性能，可能会对指令进行重排序。单线程下重排序不影响结果，但多线程下就可能出问题。

经典例子：

```java
int a = 0;
boolean flag = false;

// 线程A
a = 1;         // 语句1
flag = true;   // 语句2

// 线程B
if (flag) {
    int b = a; // 期望 b = 1，但可能是 0
}
```

线程 A 里语句 1 和语句 2 可能被重排，先执行 `flag = true`，再执行 `a = 1`。线程 B 看到 flag 为 true 了，但 a 还是 0。

volatile 能禁止特定的指令重排序。对 volatile 变量的写操作，会保证写之前的操作不会被重排到写之后。

## happens-before 规则

JMM 用 happens-before 关系来描述两个操作之间的内存可见性。如果操作 A happens-before 操作 B，那 A 的结果对 B 可见。

跟 volatile 相关的规则：对一个 volatile 变量的写操作 happens-before 后续对这个变量的读操作。

这个规则加上传递性，就能保证上面例子的正确性：
- `a = 1` happens-before `flag = true`（程序顺序规则）
- `flag = true` happens-before 线程 B 读 flag（volatile 规则）
- 所以 `a = 1` happens-before 线程 B 读 a（传递性）

happens-before 这个概念比较抽象，但搞懂它对理解并发很重要。

## volatile 的底层实现：内存屏障

volatile 在底层是通过内存屏障（Memory Barrier）实现的。

写 volatile 变量的时候，JVM 会在写操作前插入 StoreStore 屏障，写操作后插入 StoreLoad 屏障。读 volatile 变量的时候，会在读操作后插入 LoadLoad 和 LoadStore 屏障。

具体来说：
- **StoreStore**：保证写 volatile 之前的写操作先完成
- **StoreLoad**：保证写 volatile 对其他处理器可见（最重的一个屏障）
- **LoadLoad**：保证读 volatile 之后的读操作不会重排到前面
- **LoadStore**：保证读 volatile 之后的写操作不会重排到前面

在 x86 架构上，其实只有 StoreLoad 是真正需要的，其他的 x86 硬件本身就保证了。所以在 x86 上 volatile 的开销没那么大。

## DCL 单例中的 volatile

TODO

## volatile 不能保证原子性

TODO

---
title: "volatile 到底能保证什么"
date: 2023-07-20
categories: ["Java基础"]
tags: ["Java", "JMM", "并发"]
draft: false
---

# volatile 到底能保证什么

## Java 内存模型简单说

聊 volatile 之前，得先说说 Java 内存模型（JMM）。放心，不讲太深，够理解 volatile 就行。

JMM 规定了线程和内存之间的关系。简单理解：每个线程有自己的工作内存（你可以想象成 CPU 缓存），线程操作变量不是直接改主内存，而是先拷贝一份到工作内存，改完再写回去。

这就埋下了隐患——线程 A 改了变量，线程 B 可能看不到，因为 B 还在用自己工作内存里的旧值。

```
主内存:  x = 0
线程A工作内存: x = 0  →  x = 1  →  写回主内存
线程B工作内存: x = 0  →  还是0！没刷新！
```

这就是可见性问题。

## 可见性：volatile 的第一个保证

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

你觉得子线程能退出吗？答案是：不一定。JIT 编译器可能把 `while(flag)` 优化成 `while(true)`，因为它发现当前线程里没人改 flag。

我当时学并发的时候写了这个 demo，在本地跑真的不退出，挺震撼的。加上 volatile 就好了：

```java
private static volatile boolean flag = true;
```

volatile 保证了可见性：一个线程修改了 volatile 变量，其他线程能立刻看到最新值。

## 有序性：volatile 的第二个保证

Java 编译器和处理器为了优化性能，可能会对指令重排序。单线程下重排不影响结果（as-if-serial 语义），但多线程下就可能出事。

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

volatile 能禁止特定的重排序。对 volatile 变量的写操作，会保证写之前的操作不会被重排到写之后。

## happens-before 规则

JMM 用 happens-before 关系来描述操作间的内存可见性。如果 A happens-before B，那 A 的结果对 B 可见。

跟 volatile 相关的规则：**对一个 volatile 变量的写 happens-before 后续对它的读**。

加上传递性就够用了：
- `a = 1` happens-before `flag = true`（程序顺序规则）
- `flag = true` happens-before 线程 B 读 flag（volatile 规则）
- 所以 `a = 1` happens-before 线程 B 读 a（传递性）

happens-before 这个概念比较抽象，但理解它对搞懂并发很关键。

## 底层实现：内存屏障

volatile 在底层通过内存屏障（Memory Barrier）实现。

写 volatile 时，JVM 在写之前插入 StoreStore 屏障，写之后插入 StoreLoad 屏障。读 volatile 时，读之后插入 LoadLoad 和 LoadStore 屏障。

- **StoreStore**：保证写 volatile 之前的写操作先完成
- **StoreLoad**：保证写 volatile 对其他处理器可见（最重的屏障）
- **LoadLoad**：保证读 volatile 之后的读不会重排到前面
- **LoadStore**：保证读 volatile 之后的写不会重排到前面

在 x86 架构上，其实只有 StoreLoad 需要真正的屏障指令，其他的硬件本身就保证了。所以 x86 上 volatile 的性能开销没那么夸张。

## DCL 单例中 volatile 的作用

双重检查锁单例为什么需要 volatile？来看代码：

```java
public class Singleton {
    private static volatile Singleton instance;
    
    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // 关键
                }
            }
        }
        return instance;
    }
}
```

`instance = new Singleton()` 在字节码层面大概三步：
1. 分配内存空间
2. 调用构造方法初始化
3. 把引用赋值给 instance

不加 volatile 的话，步骤 2 和 3 可能被重排成 3、2。线程 B 在第一个 if 判断时看到 instance 不为 null，直接返回了一个还没初始化完的对象。用了就 NPE 或者各种诡异 bug。

加了 volatile，禁止了这个重排序，赋值一定在初始化之后。

顺便说一句，这个坑在 Java 5 之前是没法靠 volatile 解决的。Java 5（JSR-133）增强了 volatile 语义之后，DCL 才真正安全了。

## volatile 不能保证原子性

很多人以为 volatile 就是线程安全的，这是个常见误区。volatile 只保证可见性和有序性，**不保证原子性**。

```java
private static volatile int count = 0;

// 10个线程各执行1000次
count++;  // 这不是原子操作！
```

`count++` 实际上是读-改-写三步。就算 volatile 保证每次读到最新值，两个线程还是可能同时读到同一个值，然后各自加 1 写回，等于少加了一次。

要原子性，用 `AtomicInteger` 或者加锁：

```java
private static AtomicInteger count = new AtomicInteger(0);
count.incrementAndGet(); // CAS，原子操作
```

## 总结一下

volatile 能保证：
- **可见性**：修改后其他线程立刻可见
- **有序性**：禁止指令重排

volatile 不能保证：
- **原子性**：复合操作还是不安全

适用场景：状态标志位、DCL 中防止重排序、一写多读。多写场景还是得上锁或用原子类。

其实吧，volatile 这个关键字看着简单，背后涉及的东西不少。但只要抓住"可见性 + 有序性"这两个点，再理解 happens-before 和内存屏障，就差不多了。面试够用，写代码也不会踩坑。

---
title: "线程池这玩意，用不好真的会出事"
date: 2023-02-10
categories: ["Java基础"]
tags: ["Java", "并发", "线程池"]
draft: false
---

# 线程池这玩意，用不好真的会出事

上周实验室项目出了个线上问题，排查了一下午发现是线程池配置不对导致的 OOM。这事让我意识到，线程池看着简单，用不好是真会出事的。

## 为什么要用线程池

你可能觉得，new 一个 Thread 跑任务不就完了？能跑，但有几个问题：

- 创建线程有开销，操作系统要分配栈内存、做系统调用
- 任务量大的时候无限创建线程，系统资源扛不住
- 线程太多 CPU 光忙着上下文切换，正经活干不了

线程池的思路很简单：提前创建好一批线程，任务来了从池子里拿线程执行，执行完放回去复用。

## 核心参数搞清楚

`ThreadPoolExecutor` 的构造方法有 7 个参数，面试最爱问：

```java
public ThreadPoolExecutor(
    int corePoolSize,        // 核心线程数
    int maximumPoolSize,     // 最大线程数
    long keepAliveTime,      // 非核心线程存活时间
    TimeUnit unit,           // 时间单位
    BlockingQueue<Runnable> workQueue,  // 任务队列
    ThreadFactory threadFactory,        // 线程工厂
    RejectedExecutionHandler handler    // 拒绝策略
)
```

任务提交的执行流程：

1. 当前线程数 < corePoolSize，直接创建新线程执行
2. 当前线程数 >= corePoolSize，任务放进 workQueue 排队
3. workQueue 满了，且线程数 < maximumPoolSize，创建非核心线程
4. 线程数到了 maximumPoolSize 队列也满了，触发拒绝策略

注意这个顺序——是队列满了才创建超过核心数的线程。我之前一直以为先涨线程数再放队列，看源码才发现搞反了。

## 四种拒绝策略

线程池扛不住的时候，拒绝策略决定怎么处理新来的任务：

- **AbortPolicy**（默认）：直接抛 RejectedExecutionException。简单粗暴，至少你知道任务被拒了。
- **CallerRunsPolicy**：让提交任务的线程自己跑。妙处在于调用方忙着执行就没空提交新的，天然限流。
- **DiscardPolicy**：默默丢掉，不抛异常。很危险，你完全不知道任务丢了。
- **DiscardOldestPolicy**：丢掉队列最老的任务，然后重试提交。

实际项目用得最多的是 AbortPolicy 和 CallerRunsPolicy。DiscardPolicy 千万别用，出了问题排查不出来。

## 为什么阿里规约不让用 Executors

`Executors` 有几个快捷方法创建线程池，阿里规约明确禁止使用。看看为什么。

`newFixedThreadPool` 源码：

```java
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads, 0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}
```

`LinkedBlockingQueue` 默认容量 `Integer.MAX_VALUE`，无界队列。任务堆积起来直接 OOM。

`newCachedThreadPool` 更夸张：

```java
new ThreadPoolExecutor(0, Integer.MAX_VALUE, 60L, TimeUnit.SECONDS,
                       new SynchronousQueue<Runnable>());
```

最大线程数 `Integer.MAX_VALUE`，理论上能开二十多亿个线程。

正确做法是自己 new ThreadPoolExecutor，每个参数都想清楚再填。

## 我踩过的坑

说个真实的事。实验室有个爬虫项目，学长写的代码用了 `newCachedThreadPool`，平时任务少没问题。有天我们跑大批量任务，几千个 URL 同时丢进去，线程数瞬间飙到几千，内存直接爆了。

排查了一下午，一开始以为是内存泄漏，用 jmap dump 了堆内存，发现全是线程栈占的。这才反应过来是线程池的问题。

后来改成了这样：

```java
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    10,                          // 核心线程 10 个
    20,                          // 最大 20 个
    60L, TimeUnit.SECONDS,
    new ArrayBlockingQueue<>(500),  // 有界队列，最多排 500 个任务
    new ThreadPoolExecutor.CallerRunsPolicy()  // 满了让调用方自己跑
);
```

改完再没出过问题。CallerRunsPolicy 在这个场景特别合适——爬虫不怕慢一点，别 OOM 就行。

## 实际怎么配参数

这个没有标准答案，看任务类型。

**CPU 密集型**（计算多、IO 少）：核心线程数设成 CPU 核心数 + 1。多出来那一个是为了某个线程偶尔阻塞时 CPU 不至于闲着。

**IO 密集型**（网络请求、数据库查询）：线程大部分时间在等 IO，可以多开。一般设 CPU 核心数 * 2，或者用公式 `核心数 / (1 - 阻塞系数)`。

但说实话这些都是理论值，实际最靠谱的是压测。调不同参数看吞吐量和响应时间，找到合适的平衡点。

还有个容易忽略的点：给线程起有意义的名字。用自定义 ThreadFactory：

```java
ThreadFactory factory = r -> {
    Thread t = new Thread(r);
    t.setName("crawler-pool-" + t.getId());
    return t;
};
```

出问题时看线程 dump，一眼就能认出是哪个池子的线程。不然全是 pool-1-thread-1 这种默认名，排查的时候真的头大。

---
title: "线程池这玩意，用不好真的会出事"
date: 2023-02-10
categories: ["Java基础"]
tags: ["Java", "并发", "线程池"]
draft: true
---

# 线程池这玩意，用不好真的会出事

上周实验室的项目出了个线上问题，排查了一下午发现是线程池配不对导致的 OOM。这事让我意识到，线程池这东西看着简单，用不好是真的会出事。

## 为什么要用线程池

你可能觉得，我 new 一个 Thread 跑任务不就行了？对，能跑，但有几个问题：

- 创建线程是有开销的，操作系统要分配栈内存，做系统调用
- 任务量大的时候无限创建线程，系统资源扛不住
- 线程太多了 CPU 光忙着上下文切换，正经活干不了

线程池就是解决这些问题的。提前创建好一批线程，任务来了从池子里拿线程执行，执行完放回去复用。

## 核心参数搞清楚

`ThreadPoolExecutor` 的构造方法有 7 个参数，面试最爱问的：

```java
public ThreadPoolExecutor(
    int corePoolSize,        // 核心线程数
    int maximumPoolSize,     // 最大线程数
    long keepAliveTime,      // 非核心线程的存活时间
    TimeUnit unit,           // 时间单位
    BlockingQueue<Runnable> workQueue,  // 任务队列
    ThreadFactory threadFactory,        // 线程工厂
    RejectedExecutionHandler handler    // 拒绝策略
)
```

任务提交的执行流程：

1. 当前线程数 < corePoolSize，直接创建新线程执行
2. 当前线程数 >= corePoolSize，任务放进 workQueue
3. workQueue 满了，且当前线程数 < maximumPoolSize，创建非核心线程
4. 线程数到了 maximumPoolSize，队列也满了，触发拒绝策略

注意这个顺序——队列满了才会创建超过核心数的线程。我之前一直以为是线程数先涨到 max 再放队列，看源码才发现搞反了。

## 四种拒绝策略

当线程池扛不住的时候，拒绝策略决定怎么处理新任务：

- **AbortPolicy**（默认）：直接抛 RejectedExecutionException。简单粗暴，你至少能知道任务被拒了。
- **CallerRunsPolicy**：让提交任务的线程自己执行。有个妙处——调用方线程忙着执行任务的时候，就没空提交新任务了，相当于一个天然的限流。
- **DiscardPolicy**：默默丢掉任务，不抛异常。很危险，因为你完全不知道任务丢了。
- **DiscardOldestPolicy**：丢掉队列里最老的任务，然后重试。

实际项目里用得最多的是 AbortPolicy 和 CallerRunsPolicy。DiscardPolicy 千万别用，出了问题你根本排查不出来。

## 为什么阿里规约不让用 Executors

`Executors` 提供了几个快捷方法创建线程池，但阿里开发规约明确说不让用。为啥？

```java
// 别用这个！
ExecutorService pool = Executors.newFixedThreadPool(10);
```

看看 `newFixedThreadPool` 的源码：

```java
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads, 0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}
```

看到没？用的是 `LinkedBlockingQueue`，这个队列默认容量是 `Integer.MAX_VALUE`。相当于无界队列，任务可以无限堆积。任务处理得慢、提交得快，队列越来越大，最后 OOM。

`newCachedThreadPool` 更离谱：

```java
new ThreadPoolExecutor(0, Integer.MAX_VALUE, 60L, TimeUnit.SECONDS,
                       new SynchronousQueue<Runnable>());
```

最大线程数是 `Integer.MAX_VALUE`。理论上可以创建二十多亿个线程，没 OOM 才怪。

所以正确做法是自己 new ThreadPoolExecutor，明确指定每个参数。

## 我踩过的坑

## 实际怎么配参数

---
title: "单例模式的几种写法，你用哪种？"
date: 2022-12-10
categories: ["设计模式"]
tags: ["Java", "设计模式", "单例"]
draft: true
---

# 单例模式的几种写法，你用哪种？

## 为什么需要单例

单例模式大概是最简单也最常被问到的设计模式了。面试必问，但你真的理解每种写法的区别吗？

先说为什么需要单例。有些对象全局只需要一个就够了，比如线程池、数据库连接池、配置对象。你不希望到处 new，浪费资源不说，还可能出问题。

单例的核心就两件事：构造方法私有化，提供一个全局访问点。听起来简单，但写法还挺多的。

## 饿汉式

最简单直接的写法：

```java
public class Singleton {
    private static final Singleton INSTANCE = new Singleton();
    
    private Singleton() {}
    
    public static Singleton getInstance() {
        return INSTANCE;
    }
}
```

类加载的时候就创建实例了，所以叫"饿汉"——还没等你要，它就准备好了。

优点：简单，线程安全（JVM 类加载机制保证的）。
缺点：不管用不用都会创建，如果这个对象很重，就有点浪费。

说实话，大部分场景用饿汉式就够了。你的单例对象真的那么重吗？多数时候并不是。

## 懒汉式

既然饿汉式可能浪费，那就等需要的时候再创建呗：

```java
public class Singleton {
    private static Singleton instance;
    
    private Singleton() {}
    
    public static Singleton getInstance() {
        if (instance == null) {
            instance = new Singleton();
        }
        return instance;
    }
}
```

这就是懒汉式——用的时候才创建。

但问题来了：多线程环境下不安全。两个线程同时判断 `instance == null`，都通过了，就会创建两个实例。

加个 synchronized 可以解决：

```java
public static synchronized Singleton getInstance() {
    if (instance == null) {
        instance = new Singleton();
    }
    return instance;
}
```

但是这样每次调用 getInstance 都要加锁，性能太差了。实例已经创建好了还加锁，没必要啊。

## 双重检查锁（DCL）

为了解决懒汉式的性能问题，有了双重检查锁：

```java
public class Singleton {
    private static volatile Singleton instance;
    
    private Singleton() {}
    
    public static Singleton getInstance() {
        if (instance == null) {            // 第一次检查，不加锁
            synchronized (Singleton.class) {
                if (instance == null) {    // 第二次检查，加锁后再确认
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

第一次检查避免了不必要的加锁，第二次检查保证只创建一个实例。

注意那个 `volatile` 关键字，不能少。为什么？因为 `new Singleton()` 这行代码实际上分三步：分配内存、初始化对象、赋值引用。JVM 可能重排序，导致另一个线程拿到了还没初始化完的对象。volatile 禁止重排序，保证安全。

说到这里，DCL 的面试出现频率超高。把为什么要两次检查、为什么要 volatile 讲清楚，面试官基本满意。

## 静态内部类

```java
public class Singleton {
    private Singleton() {}
    
    private static class Holder {
        private static final Singleton INSTANCE = new Singleton();
    }
    
    public static Singleton getInstance() {
        return Holder.INSTANCE;
    }
}
```

利用了 JVM 的类加载机制：内部类 Holder 在第一次被引用时才会加载，加载的时候创建实例。既实现了延迟加载，又保证了线程安全。

我个人挺喜欢这种写法的，简洁，也不用操心并发问题。

## 枚举实现

TODO

## 到底用哪个

TODO

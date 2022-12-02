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

优点：简单，线程安全（JVM 类加载机制保证）。
缺点：不管用不用都会创建，如果这个对象很重，就有点浪费。

说实话，大部分场景用饿汉式就够了。你的单例对象真的那么重吗？多数时候并不是。

## 懒汉式

TODO

## 双重检查锁（DCL）

TODO

## 静态内部类

TODO

## 枚举实现

TODO

## 到底用哪个

TODO

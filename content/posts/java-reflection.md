---
title: "反射慢？慢多少你测过吗"
date: 2023-10-25
categories: ["Java基础"]
tags: ["Java", "反射"]
draft: true
---

# 反射慢？慢多少你测过吗

"反射很慢，尽量别用。"这话你肯定听过。但慢多少？慢在哪？我发现大部分人（包括之前的我）其实说不清楚。所以我决定自己测一下。

## 怎么获取 Class 对象

反射的入口是 Class 对象，获取方式有三种：

```java
// 方式1：类名.class
Class<?> clazz = String.class;

// 方式2：对象.getClass()
String str = "hello";
Class<?> clazz = str.getClass();

// 方式3：Class.forName()
Class<?> clazz = Class.forName("java.lang.String");
```

方式 1 和方式 2 在编译期就确定了类型，方式 3 是运行时通过类名加载，最灵活但也最慢（要做类查找和加载）。

拿到 Class 之后就可以干很多事了：

```java
// 获取所有方法
Method[] methods = clazz.getDeclaredMethods();

// 获取指定方法
Method method = clazz.getDeclaredMethod("substring", int.class);

// 获取所有字段
Field[] fields = clazz.getDeclaredFields();

// 创建实例
Object obj = clazz.getDeclaredConstructor().newInstance();
```

`getDeclaredXxx` 和 `getXxx` 有区别：前者获取本类声明的（包括 private），后者获取所有 public 的（包括继承来的）。这个小区别我之前搞混过，拿不到 private 字段，debug 了半天。

## Method.invoke 干了啥

## 实测一下到底慢多少

## 为什么反射慢

## Spring 里的反射

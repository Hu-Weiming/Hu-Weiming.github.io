---
title: "Java 泛型这几个坑你肯定踩过"
date: 2023-08-12
categories: ["Java基础"]
tags: ["Java", "泛型"]
draft: true
---

# Java 泛型这几个坑你肯定踩过

Java 泛型这东西，看着挺简单，用着也挺顺手，直到你踩了坑才发现自己根本没搞懂。我写这篇的起因是上周写作业的时候，一个泛型相关的编译错误搞了我一个多小时。

## 类型擦除到底擦了啥

Java 的泛型是假泛型。编译之后泛型信息就没了，全部变成 Object（或者上界类型）。这叫类型擦除。

什么意思呢？你写 `List<String>` 和 `List<Integer>`，编译之后在 JVM 看来都是 `List`。

来看个例子：

```java
List<String> strList = new ArrayList<>();
List<Integer> intList = new ArrayList<>();
System.out.println(strList.getClass() == intList.getClass());  // true！
```

都是同一个 Class。泛型只在编译期帮你做类型检查，运行时完全不知道 T 是什么。

这带来了一些奇怪的限制：

```java
// 以下全部编译不过
new T();              // 不知道 T 是啥，没法 new
new T[10];            // 不能创建泛型数组
T.class;              // 拿不到 T 的 Class
instanceof T;         // 运行时不知道 T 是啥
```

我之前写工具方法的时候，想在泛型方法里创建 T 的实例，死活编译不过。后来才知道要传一个 `Class<T>` 参数进去：

```java
public <T> T create(Class<T> clazz) throws Exception {
    return clazz.newInstance();
}
```

绕了一圈，本质就是因为擦除了之后不知道 T 是谁。

## 通配符 ? extends 和 ? super

## PECS 原则

## 泛型方法怎么写

## 一些容易翻车的细节

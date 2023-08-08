---
title: "Java 泛型这几个坑你肯定踩过"
date: 2023-08-12
categories: ["Java基础"]
tags: ["Java", "泛型"]
draft: true
---

# Java 泛型这几个坑你肯定踩过

Java 泛型这东西，看着挺简单，用着也顺手，直到你踩了坑才发现自己根本没搞懂。上周写作业的时候一个泛型编译错误搞了我一个多小时，气得我把泛型重新学了一遍。

## 类型擦除到底擦了啥

Java 的泛型是假泛型。编译之后泛型信息就没了，全变成 Object（或者上界类型）。这叫类型擦除。

`List<String>` 和 `List<Integer>`，编译之后在 JVM 看来都是 `List`：

```java
List<String> strList = new ArrayList<>();
List<Integer> intList = new ArrayList<>();
System.out.println(strList.getClass() == intList.getClass());  // true
```

泛型只在编译期做类型检查，运行时完全不知道 T 是什么。

这带来一些限制：

```java
new T();              // 编译不过，不知道 T 是啥
new T[10];            // 不能创建泛型数组
T.class;              // 拿不到 T 的 Class
instanceof T;         // 运行时不知道 T
```

我之前想在泛型方法里创建 T 的实例，死活编译不过。后来要传 `Class<T>` 进去才行：

```java
public <T> T create(Class<T> clazz) throws Exception {
    return clazz.newInstance();
}
```

绕一圈，就是因为擦除后不知道 T 是谁。

## 通配符 ? extends 和 ? super

这块是泛型里最让人头疼的部分。

`? extends T` 表示"T 或者 T 的子类"，叫做上界通配符。

```java
List<? extends Number> list = new ArrayList<Integer>();  // OK
Number n = list.get(0);  // OK，取出来肯定是 Number 的子类
list.add(1);             // 编译错误！
```

为什么不能 add？因为编译器只知道这个 list 里放的是"某种 Number 的子类"，但不知道具体是哪种。万一实际是 `List<Double>`，你往里面放 Integer 就炸了。所以编译器干脆不让你放。

`? super T` 表示"T 或者 T 的父类"，叫做下界通配符。

```java
List<? super Integer> list = new ArrayList<Number>();  // OK
list.add(1);             // OK，Integer 肯定能往里放
Integer i = list.get(0); // 编译错误！取出来只能是 Object
```

能 add 是因为不管实际类型是 Integer 的哪个父类，Integer 都能放进去。但取出来就不好说是什么类型了，只能当 Object 用。

说到这里你可能已经晕了，没关系，记住一个原则就行。

## PECS 原则

**P**roducer **E**xtends, **C**onsumer **S**uper。

如果你只需要从集合里读数据（生产者），用 `? extends T`。
如果你只需要往集合里写数据（消费者），用 `? super T`。

举个例子，Collections.copy 的签名：

```java
public static <T> void copy(List<? super T> dest, List<? extends T> src) {
    // src 是生产者，只读，用 extends
    // dest 是消费者，只写，用 super
}
```

我觉得 PECS 这个助记词还挺好用的。面试的时候直接甩出来，面试官一般就不会再深究了。

## 泛型方法怎么写

## 一些容易翻车的细节

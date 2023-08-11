---
title: "Java 泛型这几个坑你肯定踩过"
date: 2023-08-12
categories: ["Java基础"]
tags: ["Java", "泛型"]
draft: true
---

# Java 泛型这几个坑你肯定踩过

Java 泛型这东西，看着挺简单，用着也顺手，直到踩坑了才发现自己根本没搞懂。上周写作业一个泛型编译错误搞了我一个多小时，气得我把泛型重新学了一遍。

## 类型擦除到底擦了啥

Java 的泛型是假泛型。编译之后泛型信息就没了，全变成 Object（或者上界类型），这叫类型擦除。

`List<String>` 和 `List<Integer>`，编译之后 JVM 看来都是 `List`：

```java
List<String> strList = new ArrayList<>();
List<Integer> intList = new ArrayList<>();
System.out.println(strList.getClass() == intList.getClass());  // true
```

泛型只在编译期做类型检查，运行时完全不知道 T 是什么。

所以这些事情都做不了：

```java
new T();              // 编译不过
new T[10];            // 不能创建泛型数组
T.class;              // 拿不到 T 的 Class
instanceof T;         // 运行时不认识 T
```

想在泛型方法里创建实例？得把 `Class<T>` 传进去：

```java
public <T> T create(Class<T> clazz) throws Exception {
    return clazz.newInstance();
}
```

## 通配符 ? extends 和 ? super

这块是泛型里最让人头疼的。

`? extends T` 表示 "T 或 T 的子类"（上界通配符）：

```java
List<? extends Number> list = new ArrayList<Integer>();  // OK
Number n = list.get(0);  // OK
list.add(1);             // 编译错误！
```

为什么不能 add？编译器只知道里面是"某种 Number 的子类"，不知道具体哪种。万一实际是 `List<Double>`，你放 Integer 就出事了。所以干脆不让放。

`? super T` 表示 "T 或 T 的父类"（下界通配符）：

```java
List<? super Integer> list = new ArrayList<Number>();  // OK
list.add(1);             // OK
Integer i = list.get(0); // 编译错误，只能当 Object 取
```

能 add 是因为不管实际是 Integer 的哪个父类，Integer 都能放进去。取出来就只能当 Object 了。

## PECS 原则

**P**roducer **E**xtends, **C**onsumer **S**uper。

只读（生产者）用 `? extends T`，只写（消费者）用 `? super T`。

经典例子——`Collections.copy`：

```java
public static <T> void copy(List<? super T> dest, List<? extends T> src) {
    // src 只读，用 extends
    // dest 只写，用 super
}
```

PECS 这个助记词面试的时候可以直接甩，面试官一般就不会再深究了。

## 泛型方法怎么写

泛型方法的 `<T>` 写在返回值前面：

```java
public <T> T getFirst(List<T> list) {
    return list.get(0);
}
```

这里的 T 跟类上的泛型参数没关系，它是方法自己声明的。调用的时候编译器会自己推断 T 的类型，一般不需要显式指定。

一个常见的场景是写通用的工具方法：

```java
public <T extends Comparable<T>> T max(T a, T b) {
    return a.compareTo(b) >= 0 ? a : b;
}
```

`T extends Comparable<T>` 限定了 T 必须实现 Comparable 接口，不然没法调 compareTo。

我之前犯过一个错：把泛型方法和泛型类搞混了。泛型方法的 `<T>` 声明在方法上，它可以写在普通类里，不需要类本身是泛型的。

## 一些容易翻车的细节

**泛型数组的坑**

你不能 `new T[10]`，但可以声明泛型数组引用：

```java
List<String>[] array = new ArrayList[10];  // 可以，但有警告
```

为什么不让 new 泛型数组？因为数组是协变的（`String[]` 是 `Object[]` 的子类），泛型是不变的（`List<String>` 不是 `List<Object>` 的子类）。如果允许 new 泛型数组，类型安全就没法保证了。

**桥方法**

类型擦除之后可能出现方法签名冲突。编译器会自动生成一个桥方法（bridge method）来解决。比如：

```java
public class MyList implements Comparable<MyList> {
    public int compareTo(MyList o) { return 0; }
    // 擦除后编译器会生成：
    // public int compareTo(Object o) { return compareTo((MyList) o); }
}
```

这个一般不需要手动处理，但面试偶尔会问。

**通配符捕获**

有时候你会碰到一个奇怪的编译错误叫"capture of ?"。这通常是因为你试图把 `?` 当成一个具体类型来用了。解决办法是写一个辅助的泛型方法把 `?` 捕获成一个具体的类型参数。

说实话泛型这块的细节真的很碎，但日常开发中常用的也就那几个套路。把类型擦除、PECS 和泛型方法搞明白，基本就够用了。

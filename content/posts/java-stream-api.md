---
title: "Stream API 用起来真香，但别乱用"
date: 2024-01-18
categories: ["Java基础"]
tags: ["Java", "Stream", "函数式编程"]
draft: true
---

# Stream API 用起来真香，但别乱用

自从学了 Stream API，我写 Java 代码的风格变了很多。以前一个过滤加转换要写十几行 for 循环，现在一行链式调用搞定。确实香。

但是用了一段时间之后也发现了一些问题，特别是并行流和性能方面，有些地方不注意会翻车。

## 基本操作过一遍

Stream 的操作分两种：中间操作（返回新的 Stream，可以链式调用）和终端操作（触发实际计算，返回结果）。

常用的中间操作：

```java
List<String> names = students.stream()
    .filter(s -> s.getScore() > 80)      // 过滤
    .map(Student::getName)                 // 转换
    .sorted()                              // 排序
    .distinct()                            // 去重
    .limit(10)                             // 取前10个
    .collect(Collectors.toList());         // 收集结果
```

这段代码的意思是：从学生列表里筛出分数大于 80 的，取名字，排序，去重，取前 10 个。用 for 循环写的话至少要十几行。

几个最常用的终端操作：

```java
// 收集到 List
List<String> list = stream.collect(Collectors.toList());

// 收集到 Map
Map<Long, Student> map = students.stream()
    .collect(Collectors.toMap(Student::getId, s -> s));

// 分组
Map<String, List<Student>> grouped = students.stream()
    .collect(Collectors.groupingBy(Student::getClassName));

// 归约
int total = numbers.stream().reduce(0, Integer::sum);

// 其他
long count = stream.count();
Optional<T> first = stream.findFirst();
boolean allMatch = stream.allMatch(predicate);
```

`Collectors` 这个工具类功能很强大，toList、toMap、groupingBy、joining 这几个用得最多。

## 几个实用的写法

## 并行流的坑

## 性能到底怎么样

## 什么时候该用什么时候不该用

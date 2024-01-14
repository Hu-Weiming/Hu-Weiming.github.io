---
title: "Stream API 用起来真香，但别乱用"
date: 2024-01-18
categories: ["Java基础"]
tags: ["Java", "Stream", "函数式编程"]
draft: true
---

# Stream API 用起来真香，但别乱用

自从学了 Stream API，写 Java 代码的风格变了很多。以前过滤加转换要写十几行 for 循环，现在一行链式调用搞定，确实香。

但用了一段时间也发现了问题，特别是并行流和性能方面，不注意会翻车。

## 基本操作过一遍

Stream 操作分两种：中间操作（返回新 Stream，可以链式调用）和终端操作（触发计算，返回结果）。

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

从学生列表里筛分数大于 80 的，取名字，排序去重取前 10 个。for 循环写的话至少十几行。

几个常用的终端操作：

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

// 匹配和查找
long count = stream.count();
Optional<T> first = stream.findFirst();
boolean allMatch = stream.allMatch(predicate);
```

## 几个实用的写法

日常开发中这几个模式很常见：

**Map 的 value 有重复 key 怎么办**

```java
// key 冲突时保留前一个
Map<String, Student> map = students.stream()
    .collect(Collectors.toMap(Student::getName, s -> s, (s1, s2) -> s1));
```

不加第三个参数的话，key 重复直接抛 IllegalStateException。我之前被这个坑过——测试数据里没有重名的，上线后有重名数据直接报错了。

**flatMap 展开嵌套集合**

```java
// 每个班级有多个学生，把所有学生展开到一个列表
List<Student> allStudents = classes.stream()
    .flatMap(c -> c.getStudents().stream())
    .collect(Collectors.toList());
```

flatMap 这个操作我一开始死活理解不了。后来想通了：map 是一对一的转换，flatMap 是一对多然后铺平。就像把一堆嵌套的盒子全拆开摊平。

**peek 调试用**

```java
List<String> result = list.stream()
    .filter(s -> s.length() > 3)
    .peek(s -> System.out.println("过滤后: " + s))
    .map(String::toUpperCase)
    .peek(s -> System.out.println("转换后: " + s))
    .collect(Collectors.toList());
```

peek 在链条中间插入一个操作但不改变元素，特别适合 debug。但别在正式代码里用 peek 做有副作用的操作，会出问题。

## 并行流的坑

Stream 加个 `.parallelStream()` 或 `.parallel()` 就变成并行流了，看着很美好。但坑不少。

**坑一：共享可变状态**

```java
// 错误示范！
List<String> result = new ArrayList<>();
list.parallelStream().forEach(s -> result.add(s));  // 线程不安全
```

ArrayList 不是线程安全的，并行流多线程往里 add 会丢数据甚至抛异常。正确做法是用 collect。

**坑二：底层用的是 ForkJoinPool.commonPool()**

并行流默认用的是全局的 ForkJoinPool，所有并行流共享。如果某个并行流的任务很慢，会影响到其他并行流。

## 性能到底怎么样

## 什么时候该用什么时候不该用

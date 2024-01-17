---
title: "Stream API 用起来真香，但别乱用"
date: 2024-01-18
categories: ["Java基础"]
tags: ["Java", "Stream", "函数式编程"]
draft: true
---

# Stream API 用起来真香，但别乱用

自从学了 Stream API，写 Java 的风格变了很多。以前过滤加转换要写十几行 for 循环，现在一行链式搞定，确实香。

但用了一段时间也踩了不少坑，特别是并行流和性能方面。

## 基本操作过一遍

Stream 操作分两种：中间操作（返回新 Stream，链式调用）和终端操作（触发计算，返回结果）。

```java
List<String> names = students.stream()
    .filter(s -> s.getScore() > 80)      // 过滤
    .map(Student::getName)                 // 转换
    .sorted()                              // 排序
    .distinct()                            // 去重
    .limit(10)                             // 取前10个
    .collect(Collectors.toList());         // 收集结果
```

几个常用的终端操作：

```java
// 收集到 Map
Map<Long, Student> map = students.stream()
    .collect(Collectors.toMap(Student::getId, s -> s));

// 分组
Map<String, List<Student>> grouped = students.stream()
    .collect(Collectors.groupingBy(Student::getClassName));

// 归约
int total = numbers.stream().reduce(0, Integer::sum);

// 匹配和查找
boolean allMatch = stream.allMatch(predicate);
Optional<T> first = stream.findFirst();
```

## 几个实用的写法

**toMap key 冲突**

```java
Map<String, Student> map = students.stream()
    .collect(Collectors.toMap(Student::getName, s -> s, (s1, s2) -> s1));
```

不加第三个参数，key 重复直接抛 IllegalStateException。我被这个坑过——测试数据没有重名，上线后有重名直接报错。

**flatMap 展开嵌套**

```java
List<Student> allStudents = classes.stream()
    .flatMap(c -> c.getStudents().stream())
    .collect(Collectors.toList());
```

map 是一对一转换，flatMap 是一对多然后铺平。像拆嵌套盒子一样全摊开。

**peek 调试**

```java
list.stream()
    .filter(s -> s.length() > 3)
    .peek(s -> System.out.println("过滤后: " + s))
    .map(String::toUpperCase)
    .collect(Collectors.toList());
```

peek 不改变元素，适合在链条中间插入 debug 输出。但别在正式代码里用 peek 做有副作用的操作。

## 并行流的坑

`.parallelStream()` 看着很美好，坑不少。

**坑一：共享可变状态**

```java
// 错误！
List<String> result = new ArrayList<>();
list.parallelStream().forEach(s -> result.add(s));  // 线程不安全
```

ArrayList 不是线程安全的，多线程 add 会丢数据。正确做法是用 collect。

**坑二：用的是全局 ForkJoinPool**

并行流默认用 `ForkJoinPool.commonPool()`，所有并行流共享。某个流的任务很慢，会影响其他的。

如果要用独立线程池可以这样：

```java
ForkJoinPool customPool = new ForkJoinPool(4);
customPool.submit(() ->
    list.parallelStream().forEach(s -> process(s))
).get();
```

**坑三：数据量小的时候反而更慢**

并行有线程调度开销。数据量几百几千的，串行比并行快。我测过一个列表只有 200 个元素，parallel 反而慢了两倍。

## 性能到底怎么样

Stream 比 for 循环慢吗？答案是：看情况。

简单操作（遍历、求和），Stream 和 for 循环差距很小，甚至 Stream 的某些原始类型流（IntStream）可以做到持平。

复杂操作（多级 filter + map + collect），Stream 可能比手写循环稍慢一点，因为有中间对象创建和函数调用的开销。但通常在 10%-20% 以内。

大数据量 + 并行流，Stream 可能比手写循环快，因为 ForkJoinPool 能自动利用多核。

实际开发中，可读性通常比这点性能差异重要得多。除非你在写一个每秒调用几百万次的热路径，否则不用纠结性能。

## 什么时候该用什么时候不该用

**适合用的场景：**
- 集合的过滤、转换、聚合操作
- 数据量不大，可读性优先
- 需要分组、统计的场景（groupingBy、counting 等）

**不太适合的场景：**
- 需要在循环中修改外部变量（Stream 里不鼓励副作用）
- 逻辑特别复杂、多层嵌套的 lambda（可读性反而变差）
- 循环体需要 break/continue/return 的（Stream 没有直接支持的方式）
- 需要用到下标的遍历

有一个判断标准挺实用的：如果你的 Stream 链条超过 5-6 个操作，或者 lambda 里面逻辑超过 3 行，就该考虑拆成方法引用或者回到 for 循环了。可读性永远排在第一位。

---
title: "Java Stream API 使用笔记"
date: 2024-01-18
categories: ["Java基础"]
tags: ["Java", "Stream", "函数式编程"]
draft: false
---

# Stream API 用起来真香，但别乱用

自从学了 Stream API，写 Java 的风格变了不少。以前过滤加转换要写十几行 for 循环，现在一行链式搞定，确实香。

但用了一段时间也踩了不少坑，特别是并行流和性能方面，今天来聊聊。

## 基本操作过一遍

Stream 操作分两种：中间操作（返回新 Stream，可以链式调用）和终端操作（触发计算，产出结果）。

```java
List<String> names = students.stream()
    .filter(s -> s.getScore() > 80)      // 过滤
    .map(Student::getName)                 // 转换
    .sorted()                              // 排序
    .distinct()                            // 去重
    .limit(10)                             // 取前10
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

**toMap key 冲突处理**

```java
Map<String, Student> map = students.stream()
    .collect(Collectors.toMap(Student::getName, s -> s, (s1, s2) -> s1));
```

不加第三个参数，key 重复直接抛 IllegalStateException。我被这个坑过——测试数据没重名的，上线后有重名数据直接炸了。

**flatMap 展开嵌套**

```java
List<Student> allStudents = classes.stream()
    .flatMap(c -> c.getStudents().stream())
    .collect(Collectors.toList());
```

map 是一对一转换，flatMap 是一对多再铺平。像拆嵌套盒子全摊开。

**peek 调试**

```java
list.stream()
    .filter(s -> s.length() > 3)
    .peek(s -> System.out.println("过滤后: " + s))
    .map(String::toUpperCase)
    .collect(Collectors.toList());
```

peek 不改变元素，适合链条中间插入 debug 输出。但别在生产代码里用 peek 做有副作用的事。

## 并行流的坑

`.parallelStream()` 看着美好，坑不少。

**坑一：共享可变状态**

```java
// 错误示范
List<String> result = new ArrayList<>();
list.parallelStream().forEach(s -> result.add(s));  // 线程不安全！
```

ArrayList 不是线程安全的，多线程 add 会丢数据甚至抛异常。正确做法是用 collect。

**坑二：全局共享 ForkJoinPool**

并行流默认用 `ForkJoinPool.commonPool()`，所有并行流共享。某个流里任务很慢会拖累其他的。

想用独立线程池：

```java
ForkJoinPool customPool = new ForkJoinPool(4);
customPool.submit(() ->
    list.parallelStream().forEach(s -> process(s))
).get();
```

**坑三：数据量小反而更慢**

并行有线程调度开销。数据量几百几千的时候串行比并行快。我测过一个 200 元素的列表，parallel 反而慢了两倍。

## 性能到底怎么样

Stream 比 for 循环慢吗？看情况。

简单操作（遍历、求和），差距很小。IntStream 这类原始类型流基本能跟 for 持平。

复杂操作（多级 filter + map + collect），Stream 可能稍慢，因为有中间对象创建和函数调用开销。但通常在 10%-20% 以内。

大数据量 + 并行流，Stream 可能比手写循环快，ForkJoinPool 能自动利用多核。

实际开发中可读性比这点性能差异重要得多。除非你在写每秒调用几百万次的热路径，不用纠结这个。

## 什么时候该用什么时候不该用

**适合用：**
- 集合的过滤、转换、聚合
- 数据量不大，可读性优先
- 分组、统计场景（groupingBy、counting）

**不太适合：**
- 循环中需要修改外部变量（Stream 不鼓励副作用）
- 逻辑复杂、lambda 嵌套很深（可读性反而变差）
- 需要 break/continue/return 的循环
- 需要用到下标的遍历

有个判断标准挺实用：Stream 链条超过 5-6 个操作，或者 lambda 逻辑超过 3 行，就该考虑拆成方法引用或回到 for 循环。可读性永远排第一位。

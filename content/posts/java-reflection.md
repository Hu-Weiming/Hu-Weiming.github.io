---
title: "反射慢？慢多少你测过吗"
date: 2023-10-25
categories: ["Java基础"]
tags: ["Java", "反射"]
draft: true
---

# 反射慢？慢多少你测过吗

"反射很慢，尽量别用。"这话你肯定听过。但到底慢多少？慢在哪？大部分人（包括之前的我）说不清楚。所以我决定自己测一下。

## 怎么获取 Class 对象

反射的入口是 Class 对象，三种获取方式：

```java
// 方式1：类名.class
Class<?> clazz = String.class;

// 方式2：对象.getClass()
String str = "hello";
Class<?> clazz = str.getClass();

// 方式3：Class.forName()
Class<?> clazz = Class.forName("java.lang.String");
```

方式 1 和 2 编译期就确定了类型，方式 3 是运行时按类名加载，最灵活但也最慢。

拿到 Class 之后可以拿方法、字段、构造器：

```java
Method method = clazz.getDeclaredMethod("substring", int.class);
Field[] fields = clazz.getDeclaredFields();
Object obj = clazz.getDeclaredConstructor().newInstance();
```

`getDeclaredXxx` 和 `getXxx` 有区别——前者拿本类声明的（包括 private），后者拿 public 的（包括继承的）。这个我之前搞混过，拿不到 private 字段 debug 了半天。

## Method.invoke 干了啥

反射调用方法用 `Method.invoke`：

```java
Method method = clazz.getDeclaredMethod("length");
Object result = method.invoke("hello");  // 返回 5
```

如果方法是 private 的，需要先 `method.setAccessible(true)` 打开访问权限。

invoke 底层做了什么？简单来说：

1. 检查方法的访问权限
2. 检查参数类型是否匹配
3. 如果调用次数少于 15 次，走 NativeMethodAccessorImpl（JNI 调用）
4. 超过 15 次之后，JVM 会动态生成一个字节码类来做调用，避免 JNI 开销

这个 15 次的阈值可以通过 `-Dsun.reflect.inflationThreshold` 调整。前 15 次用 native 实现是因为生成字节码本身有开销，调用次数少的话不划算。

## 实测一下到底慢多少

光说不练没意思，写段代码测一下。我用一个简单的类，对比直接调用和反射调用的耗时：

```java
public class ReflectionBenchmark {
    public static void main(String[] args) throws Exception {
        MyService service = new MyService();
        Method method = MyService.class.getDeclaredMethod("doSomething");
        method.setAccessible(true);

        // 预热
        for (int i = 0; i < 100000; i++) {
            service.doSomething();
            method.invoke(service);
        }

        int times = 10_000_000;

        // 直接调用
        long start = System.nanoTime();
        for (int i = 0; i < times; i++) {
            service.doSomething();
        }
        long directTime = System.nanoTime() - start;

        // 反射调用
        start = System.nanoTime();
        for (int i = 0; i < times; i++) {
            method.invoke(service);
        }
        long reflectTime = System.nanoTime() - start;

        System.out.println("直接调用: " + directTime / 1_000_000 + "ms");
        System.out.println("反射调用: " + reflectTime / 1_000_000 + "ms");
        System.out.println("反射/直接: " + (double) reflectTime / directTime);
    }
}
```

我在自己电脑上跑了几次（JDK 11，M1 Mac），结果大概是反射比直接调用慢 3-5 倍。注意这是已经过了 15 次阈值、用上动态生成字节码之后的数据。

3-5 倍听着很多，但算算绝对时间：一千万次反射调用也就几十毫秒。你的业务逻辑花的时间、数据库查询的时间，比这大几个数量级。

## 为什么反射慢

## Spring 里的反射

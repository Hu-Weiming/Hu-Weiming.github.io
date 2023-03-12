---
title: "Spring IOC 到底干了啥"
date: 2023-03-20
categories: ["Spring"]
tags: ["Java", "Spring", "IOC"]
draft: true
---

# Spring IOC 到底干了啥

学 Spring 的时候，IOC（控制反转）这个词听了不下一百遍。老师讲、教程讲、面试题也讲。但我一开始真没搞懂这玩意到底在干嘛——不就是 new 一个对象吗，为啥要搞得这么复杂？

后来写项目写多了才明白，Spring 的 IOC 容器本质上就是帮你管理对象的。你不用自己 new，它帮你 new，帮你组装，帮你销毁。听着简单，但里面门道挺多的。

## Bean 生命周期——从出生到死亡

一个 Bean 从创建到被 GC 回收，中间经历了不少事。大致流程是这样的：

1. 实例化（调构造方法）
2. 属性赋值（依赖注入）
3. 初始化（各种回调）
4. 使用
5. 销毁

其实吧，光说这几步看着挺简单，但 Spring 在中间插了一堆扩展点。比如 `BeanPostProcessor`，它可以在初始化前后做一些操作。AOP 的代理对象就是在这一步生成的。

我之前踩过一个坑：在构造方法里去调用另一个 Bean 的方法，结果拿到的是 null。debug 了半天才发现，构造方法执行的时候依赖注入还没开始呢！所以如果有初始化逻辑，老老实实用 `@PostConstruct` 或者实现 `InitializingBean`。

```java
@Component
public class MyService {
    
    @Autowired
    private UserDao userDao;
    
    @PostConstruct
    public void init() {
        // 这里才能安全地用 userDao
        userDao.loadCache();
    }
}
```

## BeanFactory 和 ApplicationContext，到底用哪个

## 依赖注入的几种方式

## 循环依赖怎么解决的

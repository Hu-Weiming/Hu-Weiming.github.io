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

你可能会想，这俩都是 IOC 容器，有啥区别？

简单说，`BeanFactory` 是爹，`ApplicationContext` 是儿子。ApplicationContext 继承了 BeanFactory，在它基础上加了一堆功能：

- 国际化（`MessageSource`）
- 事件机制（`ApplicationEventPublisher`）
- 资源加载（`ResourceLoader`）
- AOP 支持

日常开发你基本不会直接用 `BeanFactory`。用 `ApplicationContext` 就对了。

还有个重要区别：BeanFactory 是懒加载，用到 Bean 的时候才去创建。ApplicationContext 默认是饿加载，启动的时候就把单例 Bean 全创建好了。这也是为啥 Spring Boot 启动有时候比较慢——它在启动阶段把所有 Bean 都实例化了。

## 依赖注入的几种方式

Spring 的依赖注入有三种姿势：

**1. 字段注入（最偷懒的写法）**

```java
@Component
public class OrderService {
    @Autowired
    private UserService userService;
}
```

写起来最爽，但 Spring 官方其实不推荐。为啥？因为它依赖反射，没法做 final 字段，而且单元测试的时候不好 mock。

**2. Setter 注入**

```java
@Component
public class OrderService {
    private UserService userService;
    
    @Autowired
    public void setUserService(UserService userService) {
        this.userService = userService;
    }
}
```

**3. 构造器注入（官方推荐）**

```java
@Component
public class OrderService {
    private final UserService userService;
    
    public OrderService(UserService userService) {
        this.userService = userService;
    }
}
```

构造器注入的好处：字段可以是 final 的，依赖关系一目了然，Spring 4.3 之后如果只有一个构造方法连 `@Autowired` 都不用写。配合 Lombok 的 `@RequiredArgsConstructor` 简直完美。

说到这里，我个人项目里基本都用构造器注入了。一开始觉得麻烦，用了之后发现代码清爽多了。

## 循环依赖怎么解决的

这是面试高频题。什么是循环依赖？就是 A 依赖 B，B 又依赖 A。

Spring 用三级缓存来解决这个问题。说实话这部分我看源码看了好几遍才搞明白。

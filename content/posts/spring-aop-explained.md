---
title: "AOP 这东西，说难不难说简单不简单"
date: 2023-06-15
categories: ["Spring"]
tags: ["Java", "Spring", "AOP"]
draft: true
---

# AOP 这东西，说难不难说简单不简单

AOP，面向切面编程。第一次听到这个词的时候我满脸问号——什么切面？切什么？

后来我换了个理解方式就通了：你有一堆业务方法，想在每个方法执行前后都打个日志，怎么办？一个个方法里加 `log.info()`？那要是有 200 个方法呢？改到吐。AOP 就是帮你把这种"横切"的逻辑抽出来，统一处理。

## 什么是 AOP，为什么需要它

OOP 的核心是纵向的继承和封装，但有些逻辑是横向的——日志、事务、权限校验，这些跟具体业务没关系，但到处都要用。如果每个方法都写一遍，代码重复不说，后续改起来也要命。

AOP 的思路是：你定义好在"哪些方法"的"什么时机"执行"什么逻辑"，框架帮你织入。业务代码完全不用动。

## 动态代理：JDK vs CGLIB

AOP 的底层实现靠的是动态代理。Spring 用了两种：

**JDK 动态代理**：基于接口的。你的类必须实现一个接口，代理对象也实现这个接口，通过 `InvocationHandler` 来拦截方法调用。

```java
public class MyInvocationHandler implements InvocationHandler {
    private Object target;
    
    public MyInvocationHandler(Object target) {
        this.target = target;
    }
    
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("方法执行前");
        Object result = method.invoke(target, args);
        System.out.println("方法执行后");
        return result;
    }
}
```

**CGLIB 动态代理**：基于继承的。不需要接口，直接继承目标类，重写方法来实现拦截。底层用的是 ASM 字节码操作框架。

那 Spring 怎么选？默认规则是：目标类实现了接口就用 JDK 代理，没实现接口就用 CGLIB。不过 Spring Boot 2.x 之后默认全用 CGLIB 了，因为 JDK 代理有时候会有类型转换问题。

## 切面、切点、通知——概念别搞混

## 实际应用：日志、事务、权限

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

**JDK 动态代理**：基于接口。你的类必须实现一个接口，代理对象也实现这个接口，通过 `InvocationHandler` 拦截方法调用。

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

**CGLIB 动态代理**：基于继承。不需要接口，直接继承目标类，重写方法来实现拦截。底层用的是 ASM 字节码操作框架。

那 Spring 怎么选？默认规则是：目标类实现了接口就用 JDK 代理，没实现接口就用 CGLIB。不过 Spring Boot 2.x 之后默认全用 CGLIB 了，因为 JDK 代理有时候会有类型转换的坑。

## 切面、切点、通知——概念别搞混

这几个概念刚学的时候容易绕，我用大白话说一下：

- **切面（Aspect）**：就是你写的那个类，里面定义了"在哪里做什么"
- **切点（Pointcut）**：定义"在哪里"，用表达式匹配目标方法
- **通知（Advice）**：定义"做什么"以及"什么时候做"

通知有五种类型：

| 类型 | 注解 | 执行时机 |
|------|------|----------|
| 前置通知 | `@Before` | 方法执行前 |
| 后置通知 | `@After` | 方法执行后（不管是否异常） |
| 返回通知 | `@AfterReturning` | 方法正常返回后 |
| 异常通知 | `@AfterThrowing` | 方法抛异常后 |
| 环绕通知 | `@Around` | 包裹目标方法，最强大 |

一个完整的切面长这样：

```java
@Aspect
@Component
public class LogAspect {
    
    @Pointcut("execution(* com.example.service.*.*(..))")
    public void servicePointcut() {}
    
    @Around("servicePointcut()")
    public Object around(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.currentTimeMillis();
        String methodName = pjp.getSignature().getName();
        log.info("开始执行: {}", methodName);
        
        try {
            Object result = pjp.proceed();
            log.info("执行完成: {}, 耗时: {}ms", methodName, System.currentTimeMillis() - start);
            return result;
        } catch (Throwable e) {
            log.error("执行异常: {}", methodName, e);
            throw e;
        }
    }
}
```

切点表达式那个 `execution(* com.example.service.*.*(..))` 初看挺唬人的。拆开看其实很简单：返回值任意、com.example.service 包下任意类的任意方法、参数任意。

我之前犯过一个错：切点表达式写错了，结果整个项目的方法都被拦截了，启动的时候巨慢。排查了半天才发现是少写了一层包名。所以写切点表达式的时候一定要小心，范围别搞太大。

## 实际应用：日志、事务、权限

话说回来，AOP 在实际项目里用得最多的场景有哪些？

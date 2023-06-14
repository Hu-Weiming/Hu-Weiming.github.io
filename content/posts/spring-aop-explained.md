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

**CGLIB 动态代理**：基于继承。不需要接口，直接继承目标类，重写方法来实现拦截。底层用 ASM 字节码操作框架。

那 Spring 怎么选？默认规则是：目标类实现了接口就用 JDK 代理，没实现接口就用 CGLIB。不过 Spring Boot 2.x 之后默认全用 CGLIB 了，因为 JDK 代理有时候会有类型转换的坑。

我之前碰到过一个诡异的 bug：明明注入的是接口类型，强转成实现类就报 ClassCastException。原因就是 JDK 代理生成的代理类跟实现类没有继承关系，你当然转不了。换成 CGLIB 就好了。

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

切点表达式 `execution(* com.example.service.*.*(..))` 初看挺唬人的。拆开看很简单：返回值任意、com.example.service 包下任意类的任意方法、参数任意。

我之前犯过一个错：切点表达式写错了，结果整个项目的方法都被拦截了，启动巨慢。排查了半天才发现少写了一层包名。所以写切点表达式一定要小心，范围别搞太大。

## 实际应用：日志、事务、权限

话说回来，AOP 在实际项目里用得最多的场景有哪些？

**1. 统一日志**

上面那个例子就是。方法执行时间、入参出参，用 AOP 统一记录，业务代码干干净净。

**2. 声明式事务**

Spring 的 `@Transactional` 就是 AOP 实现的。你加个注解，Spring 就在方法前开事务、正常返回就提交、抛异常就回滚。

```java
@Transactional
public void transfer(Long fromId, Long toId, BigDecimal amount) {
    accountDao.deduct(fromId, amount);
    accountDao.add(toId, amount);
}
```

这里有个经典的坑：同一个类里方法 A 调方法 B，B 上面的 `@Transactional` 不生效。为啥？因为 AOP 是通过代理对象拦截的，类内部调用走的是 this，不经过代理。解决办法是注入自己或者用 `AopContext.currentProxy()`。

**3. 权限校验**

自定义一个注解，比如 `@RequireAdmin`，然后写个切面拦截带这个注解的方法，检查当前用户权限。

```java
@Aspect
@Component
public class AuthAspect {
    
    @Before("@annotation(requireAdmin)")
    public void checkAdmin(RequireAdmin requireAdmin) {
        User user = SecurityContextHolder.getContext().getUser();
        if (!user.isAdmin()) {
            throw new AccessDeniedException("需要管理员权限");
        }
    }
}
```

这种方式比在每个 Controller 方法里写 if 判断优雅多了。

## 几个容易踩的坑

1. **private 方法 AOP 不生效**：代理只能拦截 public 方法
2. **final 类/方法 CGLIB 搞不定**：CGLIB 是基于继承的，final 没法继承
3. **@Transactional 的 self-invocation 问题**：上面说了，类内部调用不走代理
4. **切面执行顺序**：多个切面的顺序用 `@Order` 控制，数值越小优先级越高

## 小结

AOP 本质上就是动态代理 + 拦截器模式。理解了动态代理，AOP 就没啥神秘的了。日常开发中用好 `@Transactional` 和自定义注解 + 切面，能省不少事。记住那几个坑就行。

---
title: "反射慢？慢多少你测过吗"
date: 2023-10-25
categories: ["Java基础"]
tags: ["Java", "反射"]
draft: true
---

# 反射慢？慢多少你测过吗

"反射很慢，尽量别用。"这话你肯定听过。但到底慢多少？慢在哪？大部分人说不清楚。我也说不清楚，所以就自己测了一下。

## 怎么获取 Class 对象

反射的入口是 Class 对象，三种获取方式：

```java
// 方式1：类名.class
Class<?> clazz = String.class;

// 方式2：对象.getClass()
Class<?> clazz = "hello".getClass();

// 方式3：Class.forName()
Class<?> clazz = Class.forName("java.lang.String");
```

方式 1 和 2 编译期就确定了类型，方式 3 运行时按类名加载，最灵活也最慢。

拿到 Class 之后就能拿方法、字段、构造器：

```java
Method method = clazz.getDeclaredMethod("substring", int.class);
Field[] fields = clazz.getDeclaredFields();
Object obj = clazz.getDeclaredConstructor().newInstance();
```

`getDeclaredXxx` 拿本类声明的（包括 private），`getXxx` 拿 public 的（包括继承的）。这个我之前搞混过，拿不到 private 字段 debug 了半天。

## Method.invoke 干了啥

```java
Method method = clazz.getDeclaredMethod("length");
Object result = method.invoke("hello");  // 返回 5
```

private 方法需要先 `method.setAccessible(true)`。

invoke 底层的逻辑：

1. 检查访问权限
2. 检查参数类型
3. 调用次数不到 15 次，走 NativeMethodAccessorImpl（JNI 调用）
4. 超过 15 次，JVM 动态生成字节码类来调用

前 15 次用 native 是因为生成字节码本身有开销，调用少的话不划算。这个阈值可以通过 `-Dsun.reflect.inflationThreshold` 调整。

## 实测一下到底慢多少

写段代码测测：

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

我的电脑上（JDK 11）跑了几次，反射大概比直接调用慢 3-5 倍。这是过了 15 次阈值、用上动态字节码之后的数据。

3-5 倍听着吓人，但看绝对值——一千万次反射调用也就几十毫秒。你的业务逻辑和数据库查询花的时间比这大好几个数量级。

## 为什么反射慢

分析一下反射慢的几个原因：

**1. 没法内联优化。** JIT 编译器对直接调用可以做方法内联，把被调方法的代码直接嵌到调用处，省掉方法调用开销。反射调用的目标方法不确定，JIT 做不了这个优化。

**2. 参数的装箱拆箱。** invoke 的参数是 Object 数组，基本类型要装箱。返回值也是 Object，拿到之后可能还要拆箱。这些都有开销。

**3. 权限检查。** 每次 invoke 都要检查访问权限（除非你 setAccessible(true) 了）。setAccessible 之后确实能快一些。

**4. 方法查找。** `getDeclaredMethod` 每次都要在方法列表里搜索，所以 Method 对象要缓存起来复用，别每次都 getDeclaredMethod。

## Spring 里的反射

你可能觉得反射离日常开发很远，其实不是。Spring 框架到处都在用反射。

**依赖注入**：`@Autowired` 注入的时候，Spring 用反射设置字段值。大概的逻辑就是拿到 Field 对象，setAccessible(true)，然后 field.set(bean, value)。

**AOP 代理**：Spring AOP 的 JDK 动态代理底层也是反射。`InvocationHandler.invoke` 里最终通过 `Method.invoke` 调用目标方法。

**Bean 创建**：Spring 容器创建 Bean 的时候，用反射调用构造器。`clazz.getDeclaredConstructor().newInstance()`。

**注解处理**：`@Controller`、`@Service` 这些注解，Spring 启动的时候通过反射扫描类上的注解来识别。

所以你看，反射虽然慢一点，但 Spring 整个框架都建立在反射之上。框架启动的时候用反射做初始化，运行时的热路径尽量避开反射，这是一种权衡。

话说回来，如果你真的对性能有极致要求（比如写序列化框架），可以看看 `MethodHandle` 或者直接用字节码生成。但对大部分业务代码来说，反射的性能完全够用，不必过早优化。

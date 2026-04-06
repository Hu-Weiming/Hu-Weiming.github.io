---
title: "Java 反射机制与性能"
date: 2023-10-25
categories: ["Java基础"]
tags: ["Java", "反射"]
draft: false
---

# 反射慢？慢多少你测过吗

"反射很慢，尽量别用。"这话你肯定听过。但到底慢多少？慢在哪？大部分人说不清楚，我之前也说不清楚，干脆自己测了一下。

## 怎么获取 Class 对象

反射的入口是 Class 对象，三种方式：

```java
// 方式1：编译期就确定了
Class<?> clazz = String.class;

// 方式2：从已有对象获取
Class<?> clazz = "hello".getClass();

// 方式3：运行时按类名加载
Class<?> clazz = Class.forName("java.lang.String");
```

方式 1 和 2 编译期就确定类型了，方式 3 运行时按名字找，最灵活也最慢。

拿到 Class 之后就能获取方法、字段、构造器：

```java
Method method = clazz.getDeclaredMethod("substring", int.class);
Field[] fields = clazz.getDeclaredFields();
Object obj = clazz.getDeclaredConstructor().newInstance();
```

`getDeclaredXxx` 拿本类声明的（包括 private），`getXxx` 拿 public 的（包括继承的）。这个区别我之前搞混过，拿不到 private 字段 debug 了半天。

## Method.invoke 干了啥

```java
Method method = clazz.getDeclaredMethod("length");
Object result = method.invoke("hello");  // 返回 5
```

private 方法要先 `method.setAccessible(true)` 开权限。

invoke 底层干了几件事：

1. 检查访问权限
2. 检查参数类型匹配
3. 调用次数不到 15 次时走 JNI（native 实现）
4. 超过 15 次后 JVM 动态生成字节码类来做调用

前 15 次用 native 是因为生成字节码本身有成本，调用少的话不划算。阈值可以通过 `-Dsun.reflect.inflationThreshold` 调。

## 实测到底慢多少

写了段简单的 benchmark：

```java
public class ReflectionBenchmark {
    public static void main(String[] args) throws Exception {
        MyService service = new MyService();
        Method method = MyService.class.getDeclaredMethod("doSomething");
        method.setAccessible(true);

        // 预热，让 JIT 充分优化
        for (int i = 0; i < 100000; i++) {
            service.doSomething();
            method.invoke(service);
        }

        int times = 10_000_000;

        long start = System.nanoTime();
        for (int i = 0; i < times; i++) {
            service.doSomething();
        }
        long directTime = System.nanoTime() - start;

        start = System.nanoTime();
        for (int i = 0; i < times; i++) {
            method.invoke(service);
        }
        long reflectTime = System.nanoTime() - start;

        System.out.println("直接调用: " + directTime / 1_000_000 + "ms");
        System.out.println("反射调用: " + reflectTime / 1_000_000 + "ms");
    }
}
```

我电脑上（JDK 11）跑了几次，反射大概比直接调用慢 3-5 倍。这是已经过了 15 次阈值、用上动态字节码之后的数据。

3-5 倍听着吓人，但看绝对值——一千万次反射调用也就几十毫秒。你的业务逻辑、数据库查询花的时间比这大好几个数量级。

## 为什么反射慢

几个原因：

**没法内联。** JIT 对直接调用可以做方法内联，把目标方法代码直接嵌到调用处。反射的目标方法不确定，JIT 做不了这个优化。

**装箱拆箱。** invoke 参数是 Object 数组，基本类型要装箱，返回值也是 Object，可能还要拆箱。

**权限检查。** 每次 invoke 都检查访问权限。setAccessible(true) 之后能省掉这个开销。

**方法查找。** `getDeclaredMethod` 每次都在方法列表里搜索。所以 Method 对象一定要缓存复用，别每次调用都重新获取。

## Spring 里的反射

你可能觉得反射离业务代码很远，其实 Spring 到处在用。

**依赖注入**：`@Autowired` 底层就是拿到 Field，setAccessible(true)，然后 field.set(bean, value)。

**AOP**：JDK 动态代理的 `InvocationHandler.invoke` 最终通过 Method.invoke 调用目标方法。

**Bean 创建**：Spring 容器用反射调构造器创建 Bean 实例。

**注解扫描**：`@Controller`、`@Service` 这些注解，启动时通过反射读取类上的注解信息。

Spring 整个框架建立在反射之上。启动时用反射做初始化，运行时热路径尽量避开反射，这是一种合理的权衡。

话说回来，如果你对性能有极致要求（比如写序列化框架），可以看看 `MethodHandle` 或者直接用字节码生成（ASM、Javassist 之类的）。但大部分业务代码，反射性能完全够用，别过早优化。

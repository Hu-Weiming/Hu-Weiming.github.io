---
title: "策略模式干掉 if-else，代码瞬间清爽"
date: 2024-05-15
categories: ["设计模式"]
tags: ["Java", "设计模式", "策略模式"]
draft: true
---

# 策略模式干掉 if-else，代码瞬间清爽

## if-else 地狱

你写过这种代码吗：

```java
public double calculate(String type, double amount) {
    if ("NORMAL".equals(type)) {
        return amount;
    } else if ("VIP".equals(type)) {
        return amount * 0.9;
    } else if ("SVIP".equals(type)) {
        return amount * 0.8;
    } else if ("EMPLOYEE".equals(type)) {
        return amount * 0.7;
    } else if ("PARTNER".equals(type)) {
        return amount * 0.6;
    }
    return amount;
}
```

来，说实话，你的代码里有没有类似的？我之前实习的时候接手过一个项目，一个方法里二十多个 if-else，看得我头皮发麻。每次加个新类型就得在这坨代码里再加一个分支，改着改着就出 bug 了。

这种代码的问题很明显：违反开闭原则，每次新增逻辑都要改已有代码。而且测试也麻烦，一个方法里分支太多。

## 策略模式是什么

策略模式说白了就是：把每个 if 分支里的逻辑抽成单独的类，然后通过一个统一的接口来调用。

核心就三个角色：
- **策略接口**：定义算法的规范
- **具体策略**：每个类实现一种算法
- **上下文**：持有策略引用，负责调用

```java
// 策略接口
public interface PriceStrategy {
    double calculate(double amount);
}

// 具体策略
public class VipPriceStrategy implements PriceStrategy {
    @Override
    public double calculate(double amount) {
        return amount * 0.9;
    }
}
```

就这么简单。你可能会想，这不是更啰嗦了吗？本来一个方法搞定的事，搞出一堆类。别急，往下看。

## 用策略模式重构

TODO

## 结合 Spring 使用

TODO

## 实际业务案例

TODO

## 什么时候用策略模式

TODO

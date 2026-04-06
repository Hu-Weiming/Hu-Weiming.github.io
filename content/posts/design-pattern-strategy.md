---
title: "策略模式替代 if-else"
date: 2024-05-15
categories: ["设计模式"]
tags: ["Java", "设计模式", "策略模式"]
draft: false
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

说实话，你的代码里有没有类似的？我之前实习的时候接手过一个项目，一个方法里二十多个 if-else，看得我头皮发麻。每次加个新类型就得在这坨代码里再加一个分支，改着改着就出 bug。

这种代码的问题很明显：违反开闭原则，每次新增逻辑都要改已有代码。测试也麻烦，一个方法里分支太多，哪条路径没覆盖到都不好说。

## 策略模式是什么

策略模式说白了就是：把每个 if 分支里的逻辑抽成单独的类，通过一个统一的接口来调用。

核心三个角色：
- **策略接口**：定义算法规范
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

搞个策略工厂，用 Map 把类型和策略对应起来：

```java
public class PriceStrategyFactory {
    private static final Map<String, PriceStrategy> STRATEGY_MAP = new HashMap<>();
    
    static {
        STRATEGY_MAP.put("NORMAL", amount -> amount);
        STRATEGY_MAP.put("VIP", amount -> amount * 0.9);
        STRATEGY_MAP.put("SVIP", amount -> amount * 0.8);
        STRATEGY_MAP.put("EMPLOYEE", amount -> amount * 0.7);
        STRATEGY_MAP.put("PARTNER", amount -> amount * 0.6);
    }
    
    public static PriceStrategy getStrategy(String type) {
        return STRATEGY_MAP.getOrDefault(type, amount -> amount);
    }
}
```

调用的时候：

```java
public double calculate(String type, double amount) {
    PriceStrategy strategy = PriceStrategyFactory.getStrategy(type);
    return strategy.calculate(amount);
}
```

两行搞定，清爽多了吧。新加类型？往 Map 里加一条就行，原有逻辑完全不动。

## 结合 Spring 玩得更花

在 Spring 项目里，策略模式可以用得更舒服。让 Spring 帮你自动收集策略 Bean。

```java
public interface PriceStrategy {
    String getType(); // 每个策略声明自己处理什么类型
    double calculate(double amount);
}

@Component
public class VipPriceStrategy implements PriceStrategy {
    @Override
    public String getType() { return "VIP"; }
    
    @Override
    public double calculate(double amount) { return amount * 0.9; }
}
```

然后搞个上下文，用 `@Autowired` 把所有策略注入进来：

```java
@Component
public class PriceContext {
    private final Map<String, PriceStrategy> strategyMap;
    
    @Autowired
    public PriceContext(List<PriceStrategy> strategies) {
        strategyMap = strategies.stream()
            .collect(Collectors.toMap(PriceStrategy::getType, s -> s));
    }
    
    public double calculate(String type, double amount) {
        PriceStrategy strategy = strategyMap.get(type);
        if (strategy == null) {
            throw new IllegalArgumentException("未知类型: " + type);
        }
        return strategy.calculate(amount);
    }
}
```

这样每次加新策略，只需要新建一个类加上 `@Component`，其他地方一行都不用改。Spring 会自动把所有 PriceStrategy 的实现收集到 List 里注入。

我觉得这个写法是真的优雅。第一次看到的时候有种"原来还能这么玩"的感觉。

## 实际业务案例

说个我做过的真实场景：消息通知。系统要支持短信、邮件、站内信、企微推送多种通知方式。

最初的写法，你猜对了，又是 if-else：

```java
if ("SMS".equals(channel)) {
    sendSms(message);
} else if ("EMAIL".equals(channel)) {
    sendEmail(message);
} else if ("WECHAT_WORK".equals(channel)) {
    sendWechatWork(message);
}
```

用策略模式重构后：

```java
public interface NotifyStrategy {
    String getChannel();
    void send(Message message);
}

@Component
public class SmsNotifyStrategy implements NotifyStrategy {
    @Override
    public String getChannel() { return "SMS"; }
    
    @Override
    public void send(Message message) {
        // 调用短信 SDK
    }
}
```

后来产品说要加钉钉通知。我新建了一个 DingTalkNotifyStrategy，写完逻辑加上 @Component，结束。原来的代码一行没动。组里大佬 code review 的时候还夸了一句，开心了好久哈哈。

## 什么时候该用，什么时候别用

也别什么地方都上策略模式。如果你的 if-else 就两三个分支，而且以后基本不会变，那没必要折腾。过度设计比代码臭味更可怕。

适合用策略模式的场景：
- 分支多，而且经常要新增
- 各分支逻辑比较复杂，不是一两行能搞定的
- 希望各分支能独立测试
- 团队多人开发，不想互相冲突

其实吧，设计模式这东西，看着简单，用对时机才是关键。我之前学的时候光记概念没啥感觉，后来真正写项目才体会到它的好处。策略模式算是最实用的设计模式之一了，日常开发中用到的频率很高，强烈建议掌握。

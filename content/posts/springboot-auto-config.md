---
title: "Spring Boot 自动配置，看完你就不慌了"
date: 2023-09-05
categories: ["Spring"]
tags: ["Java", "Spring Boot", "自动配置"]
draft: true
---

# Spring Boot 自动配置，看完你就不慌了

用 Spring Boot 写项目的时候，你有没有想过：我就加了个 `spring-boot-starter-web` 依赖，Tomcat 怎么就自己跑起来了？数据源我就配了个 URL，连接池怎么就自动用上 HikariCP 了？

这背后全是自动配置在搞事情。

## @SpringBootApplication 背后藏了什么

启动类上那个 `@SpringBootApplication`，其实是个组合注解，拆开来看有三个核心的：

```java
@SpringBootConfiguration  // 本质就是 @Configuration
@EnableAutoConfiguration   // 关键！开启自动配置
@ComponentScan             // 包扫描
public @interface SpringBootApplication {
}
```

重点是 `@EnableAutoConfiguration`。这个注解里面用了 `@Import(AutoConfigurationImportSelector.class)`，这个 Selector 会去加载所有的自动配置类。

怎么加载的？它会读 `META-INF/spring.factories` 文件（Spring Boot 3.x 改成了 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`）。

## spring.factories 是怎么回事

这个文件在每个 starter 的 jar 包里都有。去解压 `spring-boot-autoconfigure` 这个 jar，就能看到里面的 `spring.factories`，密密麻麻写了一堆配置类。

格式是这样的：

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.web.servlet.WebMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,\
...
```

启动的时候 Spring Boot 会把这些类全加载进来。你可能想：这么多配置类全加载，不会很慢吗？别急，这就是条件注解的作用了。

## 条件注解——按需加载的秘密

虽然 `spring.factories` 里列了上百个配置类，但不是每个都会生效。Spring Boot 用条件注解来控制：

| 注解 | 含义 |
|------|------|
| `@ConditionalOnClass` | classpath 里有某个类才生效 |
| `@ConditionalOnMissingClass` | classpath 里没某个类才生效 |
| `@ConditionalOnBean` | 容器里有某个 Bean 才生效 |
| `@ConditionalOnMissingBean` | 容器里没某个 Bean 才生效 |
| `@ConditionalOnProperty` | 配置文件里有某个属性才生效 |

举个例子，`RedisAutoConfiguration` 的源码大概是这样：

```java
@Configuration
@ConditionalOnClass(RedisOperations.class)
@EnableConfigurationProperties(RedisProperties.class)
public class RedisAutoConfiguration {
    
    @Bean
    @ConditionalOnMissingBean(name = "redisTemplate")
    public RedisTemplate<Object, Object> redisTemplate(
            RedisConnectionFactory factory) {
        RedisTemplate<Object, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);
        return template;
    }
}
```

`@ConditionalOnClass(RedisOperations.class)` 意味着只有你引了 Redis 依赖，这个配置类才生效。`@ConditionalOnMissingBean` 意味着如果你自己定义了 redisTemplate，Spring Boot 就不会再创建。

这就是为啥 Spring Boot 叫"约定大于配置"——它帮你配好了默认值，你不满意再自己覆盖。

我之前遇到一个问题，项目里明明引了 Redis 依赖，但 RedisTemplate 注入失败。查了半天，发现是 `spring-boot-starter-data-redis` 版本跟 Spring Boot 版本不匹配，导致 `RedisOperations` 类没加载进来。条件注解一判断这类不存在，整个配置就跳过了。报错信息还是 "No qualifying bean"，很容易往错误方向排查。

## 手撸一个自定义 Starter

理解了自动配置原理，自己写一个 Starter 也不难。我之前做课程项目的时候写过一个短信发送的 Starter，过程大概是这样：

**1. 创建配置属性类**

```java
@ConfigurationProperties(prefix = "sms")
public class SmsProperties {
    private String accessKey;
    private String secretKey;
    private String signName;
    // getter setter...
}
```

**2. 写核心服务类**

```java
public class SmsService {
    private SmsProperties properties;
    
    public SmsService(SmsProperties properties) {
        this.properties = properties;
    }
    
    public void send(String phone, String templateCode, Map<String, String> params) {
        // 调用短信API发送
    }
}
```

**3. 写自动配置类**

```java
@Configuration
@ConditionalOnClass(SmsService.class)
@EnableConfigurationProperties(SmsProperties.class)
public class SmsAutoConfiguration {
    
    @Bean
    @ConditionalOnMissingBean
    @ConditionalOnProperty(prefix = "sms", name = "access-key")
    public SmsService smsService(SmsProperties properties) {
        return new SmsService(properties);
    }
}
```

**4. 注册到 spring.factories**

在 `resources/META-INF/spring.factories` 里加一行：

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.example.sms.SmsAutoConfiguration
```

这样别人引你的 starter，只需要在 `application.yml` 里配上 accessKey，SmsService 就自动注入好了。是不是挺简单的？

## debug 小技巧

如果你想看到底哪些自动配置生效了、哪些没生效，有两个办法：

1. 启动的时候加 `--debug` 参数，或者配置 `debug=true`，日志里会打印 ConditionEvaluationReport
2. 引入 `spring-boot-actuator`，访问 `/actuator/conditions` 端点

我经常用第一种，排查自动配置问题特别好使。

## 小结

Spring Boot 自动配置的核心就三步：`@EnableAutoConfiguration` 触发加载 → 读 `spring.factories` 找到配置类 → 条件注解控制哪些生效。把这个链路搞清楚了，遇到"为啥这个 Bean 没注入"之类的问题就不慌了。

---
title: "Spring Boot 自动配置，看完你就不慌了"
date: 2023-09-05
categories: ["Spring"]
tags: ["Java", "Spring Boot", "自动配置"]
draft: false
---

# Spring Boot 自动配置，看完你就不慌了

用 Spring Boot 写项目的时候，你有没有想过：我就加了个 `spring-boot-starter-web` 依赖，Tomcat 怎么就自己跑起来了？数据源我就配了个 URL，连接池怎么就自动用上 HikariCP 了？

这背后全是自动配置在搞事情。

## @SpringBootApplication 背后藏了什么

启动类上那个 `@SpringBootApplication`，其实是个组合注解：

```java
@SpringBootConfiguration  // 本质就是 @Configuration
@EnableAutoConfiguration   // 关键！开启自动配置
@ComponentScan             // 包扫描
public @interface SpringBootApplication {
}
```

重点是 `@EnableAutoConfiguration`。它里面用了 `@Import(AutoConfigurationImportSelector.class)`，这个 Selector 负责加载所有自动配置类。

怎么加载？读 `META-INF/spring.factories` 文件。Spring Boot 3.x 改成了 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`，但思路一样。

## spring.factories 是怎么回事

这个文件在每个 starter 的 jar 包里都有。去解压 `spring-boot-autoconfigure` 这个 jar，就能看到里面的 `spring.factories`，密密麻麻写了一堆配置类：

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.web.servlet.WebMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,\
...
```

启动的时候 Spring Boot 把这些类全加载进来。你可能想：这么多配置类全加载，不会很慢吗？别急，看下面。

## 条件注解——按需加载的秘密

虽然列了上百个配置类，但不是每个都会生效。Spring Boot 用条件注解控制：

| 注解 | 含义 |
|------|------|
| `@ConditionalOnClass` | classpath 里有某个类才生效 |
| `@ConditionalOnMissingClass` | classpath 里没某个类才生效 |
| `@ConditionalOnBean` | 容器里有某个 Bean 才生效 |
| `@ConditionalOnMissingBean` | 容器里没某个 Bean 才生效 |
| `@ConditionalOnProperty` | 配置文件里有某个属性才生效 |

举个例子，`RedisAutoConfiguration` 的源码大概这样：

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

`@ConditionalOnClass(RedisOperations.class)` 表示只有引了 Redis 依赖，这个配置类才生效。`@ConditionalOnMissingBean` 表示你自己定义了 redisTemplate 的话，Spring Boot 就不会再创建一个。

这就是"约定大于配置"——默认值都配好了，你不满意再覆盖。

我之前遇到一个问题，项目里明明引了 Redis 依赖，但 RedisTemplate 注入失败。查了半天，发现是 `spring-boot-starter-data-redis` 版本跟 Spring Boot 不匹配，导致 `RedisOperations` 类没加载进来。条件注解一判断这类不存在，整个配置直接跳过。报错信息还是 "No qualifying bean"，很容易往错误方向排查。

## 手撸一个自定义 Starter

理解了原理，自己写一个 Starter 也不难。我之前做课程项目的时候写过一个短信发送的 Starter，过程大概这样：

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
    private final SmsProperties properties;
    
    public SmsService(SmsProperties properties) {
        this.properties = properties;
    }
    
    public void send(String phone, String code, Map<String, String> params) {
        // 调用短信 API 发送
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

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.example.sms.SmsAutoConfiguration
```

别人引你的 starter，只需要在 `application.yml` 里配上 accessKey，SmsService 就自动可用了。

## debug 小技巧

想看哪些自动配置生效了、哪些没生效？两个办法：

1. 启动时加 `--debug` 参数，或者配置 `debug=true`，日志会打印 ConditionEvaluationReport
2. 引入 `spring-boot-actuator`，访问 `/actuator/conditions` 端点

排查"为啥这个 Bean 没注入"的时候特别好使，我经常用第一种。

## 小结

Spring Boot 自动配置的核心链路：`@EnableAutoConfiguration` 触发 → 读 `spring.factories` 找配置类 → 条件注解控制生效。搞清楚这个，遇到 Bean 注入的问题就不慌了。

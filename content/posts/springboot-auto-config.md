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

你写的启动类上面那个 `@SpringBootApplication`，其实是个组合注解，拆开来看有三个核心的：

```java
@SpringBootConfiguration  // 本质就是 @Configuration
@EnableAutoConfiguration   // 关键！开启自动配置
@ComponentScan             // 包扫描
public @interface SpringBootApplication {
}
```

重点是 `@EnableAutoConfiguration`。这个注解里面用了 `@Import(AutoConfigurationImportSelector.class)`，这个 Selector 会去加载所有的自动配置类。

怎么加载的？它会去读 `META-INF/spring.factories` 文件（Spring Boot 3.x 改成了 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`）。

## spring.factories 是怎么回事

这个文件在每个 starter 的 jar 包里都有。你去解压 `spring-boot-autoconfigure` 这个 jar，就能看到里面的 `spring.factories` 文件，密密麻麻写了一堆配置类。

格式是这样的：

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.web.servlet.WebMvcAutoConfiguration,\
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,\
org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,\
...
```

启动的时候 Spring Boot 会把这些类全加载进来。你可能想：这么多配置类全加载，不会很慢吗？别急，这就是条件注解要干的事了。

## 条件注解——按需加载的秘密

## 手撸一个自定义 Starter

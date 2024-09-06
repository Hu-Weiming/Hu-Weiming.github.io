---
title: "Spring Cloud 微服务入门，别被吓到"
date: 2024-09-10
categories: ["Spring"]
tags: ["Java", "Spring Cloud", "微服务"]
draft: true
---

# Spring Cloud 微服务入门，别被吓到

## 微服务到底是啥

第一次听"微服务"这个词的时候，我觉得好高大上。什么服务注册发现、熔断降级、链路追踪，一堆概念扑面而来。但学了之后发现，核心思路没那么复杂。

简单说，微服务就是把一个大应用拆成多个小服务，每个服务独立部署、独立运行。比如电商系统可以拆成用户服务、商品服务、订单服务、支付服务等。

为什么要拆？单体应用到后期改一个小功能就要重新部署整个系统，代码耦合严重，团队协作也别扭。拆成微服务之后，各团队负责自己的服务，独立开发独立上线。

当然微服务不是银弹，小项目上微服务纯属给自己找麻烦。但学习微服务技术栈还是很有必要的。

## 注册中心：Nacos

服务拆了之后，A 想调 B，怎么知道 B 在哪？IP 和端口写死？B 有多个实例怎么办？地址变了怎么办？

这就需要注册中心。每个服务启动时把地址注册到注册中心，其他服务去注册中心查就行了。

现在主流用 Nacos（阿里开源），同时支持服务注册和配置管理。

```yaml
spring:
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
  application:
    name: user-service
```

加上依赖，写好配置，启动就自动注册了。Nacos 控制台能看到所有注册的服务。

## 网关：Gateway

微服务拆了之后，前端调接口调哪个服务？总不能让前端知道每个服务的地址吧。网关就是统一的入口，所有请求先到网关，由网关路由到对应的服务。

Spring Cloud Gateway 是官方推荐的网关。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service  # lb 表示负载均衡
          predicates:
            - Path=/api/user/**
        - id: order-service
          uri: lb://order-service
          predicates:
            - Path=/api/order/**
```

请求 `/api/user/xxx` 自动转发到 user-service，`/api/order/xxx` 转发到 order-service。`lb://` 前缀表示从注册中心获取地址并做负载均衡。

网关除了路由，还能做鉴权、限流、日志等。比如在网关统一校验 Token，下游服务就不用每个都写鉴权逻辑了。

## 远程调用：OpenFeign

服务之间互相调用怎么搞？用 RestTemplate 手写 HTTP 请求？太麻烦了。OpenFeign 让远程调用像调本地方法一样简单。

```java
@FeignClient("user-service")
public interface UserClient {
    @GetMapping("/api/user/{id}")
    User getUser(@PathVariable Long id);
}
```

定义一个接口，加上 `@FeignClient` 注解指定服务名，然后像调普通方法一样调：

```java
@Service
public class OrderService {
    @Autowired
    private UserClient userClient;
    
    public Order createOrder(Long userId) {
        User user = userClient.getUser(userId); // 像调本地方法一样
        // 创建订单逻辑
    }
}
```

OpenFeign 会根据服务名从注册中心找到地址，自动发 HTTP 请求，还自带负载均衡。写起来真的舒服。

## 熔断降级：Sentinel

TODO

## 整体架构串一下

TODO

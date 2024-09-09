---
title: "Spring Cloud 微服务入门，别被吓到"
date: 2024-09-10
categories: ["Spring"]
tags: ["Java", "Spring Cloud", "微服务"]
draft: true
---

# Spring Cloud 微服务入门，别被吓到

## 微服务到底是啥

第一次听"微服务"这个词的时候，我觉得好高大上。什么服务注册发现、熔断降级、链路追踪，一堆概念砸过来。但学了之后发现，核心思路没那么复杂。

简单说，微服务就是把一个大应用拆成多个小服务，每个独立部署、独立运行。比如电商系统拆成用户服务、商品服务、订单服务、支付服务。

为什么要拆？单体应用到后期改个小功能就得重新部署整个系统，代码耦合严重，团队协作也别扭。微服务之后，各团队负责自己的服务，独立开发上线。

当然微服务不是银弹，小项目上微服务纯属自找麻烦。但学习技术栈是很有必要的。

## 注册中心：Nacos

服务拆了之后，A 想调 B，怎么知道 B 在哪？IP 端口写死？B 有多个实例呢？地址变了呢？

注册中心解决这个问题。每个服务启动时把地址注册上去，其他服务去查就行。

Nacos 是现在的主流选择，同时搞定服务注册和配置管理。

```yaml
spring:
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
  application:
    name: user-service
```

加依赖、写配置、启动，就注册好了。Nacos 控制台能看到所有服务，很直观。

## 网关：Gateway

微服务拆了之后，前端调哪个服务？总不能让前端记一堆地址吧。网关就是统一入口，所有请求先过网关，由网关路由到对应服务。

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/user/**
        - id: order-service
          uri: lb://order-service
          predicates:
            - Path=/api/order/**
```

`/api/user/xxx` 转发到 user-service，`/api/order/xxx` 转发到 order-service。`lb://` 前缀表示从注册中心取地址，自带负载均衡。

网关还能统一做鉴权、限流、日志。比如在网关校验 Token，下游服务就不用每个都写了。

## 远程调用：OpenFeign

服务之间调用怎么搞？手写 RestTemplate？太麻烦。OpenFeign 让远程调用像调本地方法一样。

```java
@FeignClient("user-service")
public interface UserClient {
    @GetMapping("/api/user/{id}")
    User getUser(@PathVariable Long id);
}
```

```java
@Service
public class OrderService {
    @Autowired
    private UserClient userClient;
    
    public Order createOrder(Long userId) {
        User user = userClient.getUser(userId); // 就像调本地方法
        // ...
    }
}
```

OpenFeign 根据服务名从注册中心找地址，自动发 HTTP 请求，还自带负载均衡。写起来真的舒服。

## 熔断降级：Sentinel

微服务架构有个麻烦事：服务之间有依赖，一个服务挂了可能导致调用方也跟着挂，连锁反应下去整个系统就崩了。这就是所谓的"雪崩效应"。

Sentinel（阿里开源）就是干这个的。当某个服务响应超时或者错误率太高，Sentinel 可以自动熔断，不再调用那个服务，而是直接返回一个降级响应。

```java
@FeignClient(value = "user-service", fallback = UserClientFallback.class)
public interface UserClient {
    @GetMapping("/api/user/{id}")
    User getUser(@PathVariable Long id);
}

@Component
public class UserClientFallback implements UserClient {
    @Override
    public User getUser(Long id) {
        // 降级逻辑，返回默认值
        return new User(id, "未知用户");
    }
}
```

user-service 挂了？没关系，直接返回"未知用户"，至少不会让订单服务也跟着挂。

Sentinel 还支持流量控制，可以限制每秒的请求数，防止被打爆。控制台可以实时监控和动态调整规则，很好用。

## 整体架构串一下

把这些组件串起来：

```
客户端 → Gateway(网关) → 路由到对应服务
                           ↓
                    Nacos(注册中心/配置中心)
                    ↙        ↓        ↘
              用户服务    订单服务    商品服务
                    ↖   OpenFeign   ↗
                      互相调用
                    
              Sentinel 在每个服务里做熔断限流
```

一个请求的完整流程：
1. 客户端请求到 Gateway
2. Gateway 根据路径路由到对应服务
3. 服务从 Nacos 获取其他服务的地址
4. 通过 OpenFeign 调用其他服务
5. Sentinel 监控每个调用，必要时熔断降级

Spring Cloud Alibaba 这套组件用起来还是很顺手的。我之前跟着做了个小项目练手，搞了三个服务加一个网关，跑起来之后感觉对微服务的理解清晰多了。

其实吧，微服务的组件还有很多，比如配置中心（Nacos 也能干）、链路追踪（Skywalking）、分布式事务（Seata）等。但入门的话，先把注册中心、网关、远程调用、熔断这四个搞明白就够了。

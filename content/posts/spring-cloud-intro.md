---
title: "Spring Cloud 微服务入门"
date: 2024-09-10
categories: ["Spring"]
tags: ["Java", "Spring Cloud", "微服务"]
draft: false
---

# Spring Cloud 微服务入门，别被吓到

## 微服务到底是啥

第一次听"微服务"这个词的时候，我觉得好高大上。服务注册发现、熔断降级、链路追踪，一堆概念砸过来挺吓人的。但学了之后发现，核心思路其实没那么复杂。

简单说，微服务就是把一个大应用拆成多个小服务，每个独立部署、独立运行。比如电商系统拆成用户服务、商品服务、订单服务、支付服务。

为什么要拆？单体应用到后期改个小功能就得重新部署整个系统，代码耦合严重，团队协作也别扭。微服务之后，各团队负责自己的服务，独立开发独立上线。

当然微服务不是银弹。小项目上微服务纯属自找麻烦，运维复杂度直接翻好几倍。但学习这套技术栈还是很有必要的，面试也经常问。

## 注册中心：Nacos

服务拆了之后，A 想调 B，怎么知道 B 在哪？IP 端口写死在配置里？那 B 有多个实例呢？地址变了呢？

注册中心解决这个问题。每个服务启动时把自己的地址注册上去，其他服务去查就行了。

Nacos 是现在的主流选择（阿里开源），同时搞定服务注册和配置管理。

```yaml
spring:
  cloud:
    nacos:
      discovery:
        server-addr: localhost:8848
  application:
    name: user-service
```

加上依赖、写好配置、启动，就注册好了。Nacos 控制台能看到所有注册的服务实例，很直观。

我第一次跑通的时候还挺激动的，在控制台看到自己的服务出现了，有种打通"任督二脉"的感觉。

## 网关：Gateway

微服务拆了之后，前端调哪个服务？总不能让前端记一堆服务地址。网关就是统一入口，所有请求先过网关，由网关路由到对应服务。

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

`/api/user/xxx` 自动转发到 user-service，`/api/order/xxx` 转发到 order-service。`lb://` 前缀表示从注册中心取地址，自带负载均衡。

网关还能统一做鉴权、限流、日志。在网关校验 Token，下游服务就不用每个都重复写鉴权了。

## 远程调用：OpenFeign

服务之间调用怎么搞？手写 RestTemplate 拼 URL？太折腾了。OpenFeign 让远程调用像调本地方法一样。

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
        User user = userClient.getUser(userId); // 像调本地方法一样
        // 创建订单...
    }
}
```

OpenFeign 根据服务名从注册中心找地址，自动发 HTTP 请求，还自带负载均衡。第一次用的时候觉得真方便，声明式调用太舒服了。

## 熔断降级：Sentinel

微服务有个麻烦事：服务之间有依赖，一个挂了可能连带调用方也跟着挂，连锁反应下去整个系统就崩了——这叫"雪崩效应"。

Sentinel（同样阿里开源）就是应对这个的。当某个服务响应超时或错误率太高，Sentinel 自动熔断，不再发请求过去，直接走降级逻辑。

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
        return new User(id, "未知用户"); // 降级响应
    }
}
```

user-service 挂了？没关系，返回"未知用户"，至少订单服务不会跟着挂。

Sentinel 还支持流量控制，限制每秒请求数防止服务被打爆。控制台可以实时监控、动态调规则，很好用。

## 整体架构串一下

把组件串起来看：

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

Spring Cloud Alibaba 这套组件用起来还是挺顺手的。我之前跟着做了个小项目练手，搞了三个服务加一个网关，跑起来之后对微服务的理解清晰多了。

其实吧，微服务组件远不止这些。配置中心（Nacos 也能干）、链路追踪（SkyWalking）、分布式事务（Seata）都是常见的。但入门的话，先把注册中心、网关、远程调用、熔断降级这四大件搞明白就够了，其他的用到再学不迟。

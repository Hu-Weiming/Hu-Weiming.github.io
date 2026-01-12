---
title: "Spring AI 初探：Spring 生态的 AI 新成员"
date: 2026-01-20
categories: ["AI"]
tags: ["AI", "Spring AI", "Java"]
draft: true
---

# Spring AI 初探：Spring 生态的 AI 新成员

## Spring AI 是什么

Spring 官方终于下场做 AI 框架了。Spring AI 是 Spring 生态的一部分，目标是让 Java/Spring 开发者能方便地集成各种 AI 能力。

之前 Java 圈搞 AI 主要靠 LangChain4j，现在 Spring 官方出手了，竞争来了。

Spring AI 的风格很 Spring：自动配置、Starter 依赖、注解驱动。用过 Spring Boot 的人上手会很自然。

目前 Spring AI 还在快速迭代（我写这篇的时候是 1.0.0-M5），API 可能会变。但核心概念已经比较稳定了。

## ChatClient 基本使用

Spring AI 的核心接口是 ChatClient，类似于 RestTemplate 和 WebClient 的设计思路。

先加依赖（以 OpenAI 为例）：

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-openai-spring-boot-starter</artifactId>
</dependency>
```

配置 API key：

```yaml
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY}
      chat:
        options:
          model: gpt-4o-mini
```

使用 ChatClient：

```java
@RestController
public class ChatController {
    private final ChatClient chatClient;
    
    public ChatController(ChatClient.Builder builder) {
        this.chatClient = builder.build();
    }
    
    @GetMapping("/chat")
    public String chat(@RequestParam String message) {
        return chatClient.prompt()
                .user(message)
                .call()
                .content();
    }
}
```

流式 API 的设计让代码很好读。`.prompt().user(message).call().content()`，链式调用一路下来。

## Prompt 模板

TODO

## 接入 OpenAI 和 Ollama

TODO

## 和 LangChain4j 对比

TODO

## 我的看法

TODO

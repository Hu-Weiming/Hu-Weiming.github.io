---
title: "Spring AI 初探：Spring 生态的 AI 新成员"
date: 2026-01-20
categories: ["AI"]
tags: ["AI", "Spring AI", "Java"]
draft: true
---

# Spring AI 初探：Spring 生态的 AI 新成员

## Spring AI 是什么

Spring 官方终于下场做 AI 框架了。Spring AI 是 Spring 生态的一部分，让 Java/Spring 开发者方便地集成 AI 能力。

之前 Java 搞 AI 主要靠 LangChain4j，现在 Spring 官方入局，有意思了。

Spring AI 的风格很 Spring：自动配置、Starter、注解驱动。用过 Spring Boot 的人上手会很自然。

## ChatClient 基本使用

核心接口是 ChatClient。先加依赖：

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-openai-spring-boot-starter</artifactId>
</dependency>
```

配置：

```yaml
spring:
  ai:
    openai:
      api-key: ${OPENAI_API_KEY}
      chat:
        options:
          model: gpt-4o-mini
```

用起来：

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

链式 API 很流畅，`.prompt().user(message).call().content()`。

## Prompt 模板

Spring AI 支持用 Prompt 模板来构造提示词：

```java
@GetMapping("/translate")
public String translate(@RequestParam String text, @RequestParam String lang) {
    return chatClient.prompt()
            .system("你是一个专业翻译")
            .user(u -> u.text("请将以下文本翻译成{lang}：{text}")
                    .param("lang", lang)
                    .param("text", text))
            .call()
            .content();
}
```

也可以从文件加载模板：

```java
@Value("classpath:/prompts/translate.st")
Resource translatePrompt;
```

Spring AI 用的模板引擎是 StringTemplate，语法跟 Spring 的 `@Value` 不太一样，刚开始容易搞混。我 debug 了好一会儿才发现变量占位符的格式不对。

## 接入 Ollama

除了 OpenAI，Spring AI 也支持 Ollama：

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-ollama-spring-boot-starter</artifactId>
</dependency>
```

```yaml
spring:
  ai:
    ollama:
      base-url: http://localhost:11434
      chat:
        options:
          model: qwen2.5:7b
```

代码完全不用改，ChatClient 的用法一模一样。换个 Starter 依赖和配置就切换了模型提供商。这个抽象做得不错，Spring 一贯的风格。

## 和 LangChain4j 对比

TODO

## 我的看法

TODO

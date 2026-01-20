---
title: "Spring AI 初探：Spring 生态的 AI 新成员"
date: 2026-01-20
categories: ["AI"]
tags: ["AI", "Spring AI", "Java"]
draft: false
---

# Spring AI 初探：Spring 生态的 AI 新成员

## Spring AI 是什么

Spring 官方终于下场做 AI 框架了。Spring AI 是 Spring 生态里的新成员，目标是让 Java/Spring 开发者能方便地集成各种 AI 能力。

之前 Java 圈搞 AI 开发主要靠 LangChain4j，现在 Spring 官方也入局了，竞争挺有意思的。

Spring AI 的风格很"Spring"：自动配置、Starter 依赖、注解驱动。用过 Spring Boot 的人上手会非常自然。

## ChatClient：核心 API

ChatClient 是 Spring AI 最核心的接口，设计思路类似 RestTemplate / WebClient。

先加依赖（以 OpenAI 为例）：

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

使用起来：

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

链式调用写起来很流畅：`.prompt().user(message).call().content()`。想要流式输出？把 `.call()` 换成 `.stream()` 就行。

## Prompt 模板

Spring AI 支持用模板构造提示词：

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

也能从 classpath 文件加载模板。Spring AI 用的模板引擎是 StringTemplate，变量语法跟 Spring 的 `${}`  不同，用的是 `{}`，我第一次用的时候没注意到这个差别，debug 了好一会儿。

## 无缝切换到 Ollama

想用本地模型？换个 Starter 和配置就行：

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

代码完全不动。ChatClient 的用法一模一样，只是底层换了模型提供商。这个抽象层做得确实好，典型的 Spring 设计哲学——面向接口编程。

## 和 LangChain4j 对比

两个都玩了一段时间，聊聊对比。

**Spring AI 的好处**：
- 原生 Spring 生态，自动配置省心
- ChatClient API 设计优雅，链式调用很流畅
- 切���模型后端只改配置，代码不动
- 长期来看跟 Spring 全家桶的整合会越来越深

**LangChain4j 的好处**：
- 功能更全，AiServices、Tools、Agent 更成熟
- 版本更稳定，已经有不少生产案例
- 社区活跃，文档和示例丰富
- 不绑定 Spring，更灵活

如果项目是 Spring Boot 的，Spring AI 用着确实更顺手。但需要 RAG、Agent、Function Calling 这些高级功能的话，LangChain4j 目前更完善。

我的判断：Spring AI 正式版出来之后，在 Spring 项目中大概率会成为主流选择。但现在还在早期��段，API 可能变动，生产环境要谨慎。

## 小结

Spring AI 给了 Java 开发者一个原生的 AI 集成方案。ChatClient + 自动配置的体验很好，切换不同模型后端也很方便。

其实吧，Java 生态在 AI 这块虽然起步��� Python 晚，但 Spring AI 和 LangChain4j 都在快速发展。作为 Java 开发者，现在入场 AI 开发并不晚。工具已经够用了，剩下的就是找场景去实践。

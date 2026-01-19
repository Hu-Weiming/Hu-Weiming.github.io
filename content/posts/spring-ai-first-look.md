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

之前 Java 搞 AI 主要靠 LangChain4j，现在 Spring 官方入局了。这挺有意思的，大家都在抢这块市场。

风格很 Spring：自动配置、Starter 依赖、注解驱动。用过 Spring Boot 的人上手非常自然。

## ChatClient 基本使用

核心接口是 ChatClient。加依赖：

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

链式调用很舒服，`.prompt().user(message).call().content()`。想要流式输出也简单，把 `.call()` 换成 `.stream()` 就行。

## Prompt 模板

Spring AI 支持 Prompt 模板：

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

也可以从 resource 文件加载模板。Spring AI 用的是 StringTemplate 引擎，语法跟 Spring 的 `@Value` 不一样，我第一次用的时候被坑了。

## 接入 Ollama

换 Ollama 很简单，改依赖和配置就行：

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

代码完全不用改。ChatClient 的用法一模一样，换个 Starter 就切换了后端。这个抽象做得不错。

## 和 LangChain4j 对比

两个都试了一段时间，说说我的感受：

**Spring AI 的优势**：
- 原生 Spring 生态，自动配置太舒服了
- ChatClient 的 API 设计很流畅
- 切换模型提供商只需要改配置
- 未来跟 Spring 全家桶的集成肯定会越来越好

**LangChain4j 的优势**：
- 功能更丰富，AiServices、Tools 调用更成熟
- 版本更稳定（Spring AI 还在 milestone 阶段）
- 社区更活跃，文档和示例多
- 不依赖 Spring，非 Spring 项目也能用

如果你的项目已经是 Spring Boot 的，Spring AI 用起来确实更顺手。但如果需要 RAG、Agent、Tools 这些高级功能，LangChain4j 目前更完善。

我的判断是：Spring AI 正式版出来之后，在 Spring 项目中应该会逐渐成为首选。但现在还在早期，生产环境用的话要谨慎。

## 小结

Spring AI 给了 Java 开发者一个原生的 AI 集成方案。ChatClient + 自动配置的开发体验很好，切换不同模型后端也方便。

目前还是早期阶段，API 可能变动，功能也在补齐。我会持续关注，等稳定了再考虑正式项目中使用。学习的话现在就可以上手玩了。

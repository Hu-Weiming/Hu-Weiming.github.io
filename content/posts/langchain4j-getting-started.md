---
title: "LangChain4j 初体验：Java 也能玩 LLM"
date: 2025-08-20
categories: ["AI"]
tags: ["AI", "LangChain4j", "Java"]
draft: true
---

# LangChain4j 初体验：Java 也能玩 LLM

## LangChain4j 是什么

说到 AI 开发，大家第一反应都是 Python。LangChain、LlamaIndex 这些框架清一色 Python 的。但我是写 Java 的啊，难道就不能玩了？

LangChain4j 就是来填这个坑的。它是 LangChain 的 Java 版本，提供了和 LLM 交互的各种工具：模型接入、Prompt 管理、Memory、RAG、Tools 等等。

官方 GitHub 地址是 `langchain4j/langchain4j`，star 数增长很快，说明 Java 圈对这个需求确实大。

## 快速上手

先建个 Spring Boot 项目，加依赖：

```xml
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j</artifactId>
    <version>0.35.0</version>
</dependency>
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-open-ai</artifactId>
    <version>0.35.0</version>
</dependency>
```

最简单的用法：

```java
ChatLanguageModel model = OpenAiChatModel.builder()
        .apiKey("your-api-key")
        .modelName("gpt-4o-mini")
        .build();

String answer = model.generate("Java 和 Go 哪个更适合后端开发？");
System.out.println(answer);
```

就这么几行代码，就能调大模型了。第一次跑通的时候我还挺兴奋的。

当然你也可以接 Ollama 本地模型，不花钱：

```java
ChatLanguageModel model = OllamaChatModel.builder()
        .baseUrl("http://localhost:11434")
        .modelName("qwen2.5:7b")
        .build();
```

## ChatModel 接入

TODO

## Memory：多轮对话

TODO

## 和 Python 版 LangChain 对比

TODO

## 总结

TODO

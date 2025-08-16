---
title: "LangChain4j 初体验：Java 也能玩 LLM"
date: 2025-08-20
categories: ["AI"]
tags: ["AI", "LangChain4j", "Java"]
draft: true
---

# LangChain4j 初体验：Java 也能玩 LLM

## LangChain4j 是什么

说到 AI 开发，大家第一反应都是 Python。LangChain、LlamaIndex 清一色 Python。但我主力语言是 Java 啊，难道就不能玩了？

LangChain4j 就是来填这个坑的。Java 版的 LangChain，提供和 LLM 交互的各种工具：模型接入、Prompt 管理、Memory、RAG、Tools 调用等。

## 快速上手

建个 Spring Boot 项目，加依赖：

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

几行代码就能调大模型。也可以接 Ollama 本地模型，不花钱：

```java
ChatLanguageModel model = OllamaChatModel.builder()
        .baseUrl("http://localhost:11434")
        .modelName("qwen2.5:7b")
        .build();
```

## ChatModel 的更多用法

上面用的是最简单的 `generate(String)`，实际开发中你可能需要更精细的控制。

LangChain4j 提供了 AiServices，可以把 LLM 调用包装成一个 Java 接口：

```java
public interface Assistant {
    @SystemMessage("你是一个 Java 技术专家，回答简洁明了")
    String chat(String userMessage);
}

Assistant assistant = AiServices.builder(Assistant.class)
        .chatLanguageModel(model)
        .build();

String reply = assistant.chat("Spring Boot 3 有什么新特性？");
```

这个 AiServices 是 LangChain4j 最好用的特性之一。你定义接口，框架帮你实现，很 Java 风格。`@SystemMessage` 就是系统提示词，控制模型的角色和行为。

还可以用 `@UserMessage` 做 Prompt 模板：

```java
public interface Translator {
    @UserMessage("请将以下文本翻译成{{language}}：{{text}}")
    String translate(@V("text") String text, @V("language") String language);
}
```

## Memory：多轮对话

默认情况下模型是无状态的，每次调用都是独立的。想要多轮对话，需要把历史消息传给模型。

LangChain4j 提供了 ChatMemory：

```java
ChatMemory memory = MessageWindowChatMemory.withMaxMessages(20);

Assistant assistant = AiServices.builder(Assistant.class)
        .chatLanguageModel(model)
        .chatMemory(memory)
        .build();

assistant.chat("我叫小明");
String reply = assistant.chat("我叫什么？"); 
// 模型会记住之前说的，回答"你叫小明"
```

`MessageWindowChatMemory` 是滑动窗口，保留最近 N 条消息。超过了就丢弃最早的，简单粗暴但够用。

还有 `TokenWindowChatMemory`，按 Token 数限制，更精确一些。

## 和 Python 版 LangChain 对比

TODO

## 总结

TODO

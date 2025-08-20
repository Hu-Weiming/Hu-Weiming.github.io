---
title: "LangChain4j 初体验：Java 也能玩 LLM"
date: 2025-08-20
categories: ["AI"]
tags: ["AI", "LangChain4j", "Java"]
draft: false
---

# LangChain4j 初体验：Java 也能玩 LLM

## LangChain4j 是什么

说到 AI 开发，大家第一反应都是 Python。LangChain、LlamaIndex 清一色 Python 的。但我主力语言是 Java，难道就只能干看着？

LangChain4j 就是来填这个坑的。它是 LangChain 的 Java 实现，提供了和 LLM 交互的各种能力：模型接入、Prompt 管理、Memory、RAG、Tools 调用等。GitHub 上 `langchain4j/langchain4j`，star 涨得挺快，说明 Java 圈对这个需求确实大。

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

最简单的调用：

```java
ChatLanguageModel model = OpenAiChatModel.builder()
        .apiKey("your-api-key")
        .modelName("gpt-4o-mini")
        .build();

String answer = model.generate("Java 和 Go 哪个更适合后端开发？");
System.out.println(answer);
```

几行代码就能跟大模型对话了。第一次跑通的时候还挺兴奋的。

也可以接 Ollama 跑本地模型，免费：

```java
ChatLanguageModel model = OllamaChatModel.builder()
        .baseUrl("http://localhost:11434")
        .modelName("qwen2.5:7b")
        .build();
```

## AiServices：最好用的特性

上面是最基础的字符串输入输出。实际开发中你需要更精细的控制。

LangChain4j 的 AiServices 能把 LLM 调用包装成 Java 接口，这是我觉得最好用的特性：

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

定义接口，框架帮你实现。很 Java 风格，IDE 补全也舒服。

还能搞 Prompt 模板：

```java
public interface Translator {
    @UserMessage("请将以下文本翻译成{{language}}：{{text}}")
    String translate(@V("text") String text, @V("language") String language);
}
```

调用 `translator.translate("Hello World", "中文")` 就行了，模板化之后复用方便。

## Memory：让模型记住上下文

默认模型是无状态的，每次调用独立。想要多轮对话的"记忆"，需要把历史消息传给模型。

LangChain4j 提供了 ChatMemory，用起来很简单：

```java
ChatMemory memory = MessageWindowChatMemory.withMaxMessages(20);

Assistant assistant = AiServices.builder(Assistant.class)
        .chatLanguageModel(model)
        .chatMemory(memory)
        .build();

assistant.chat("我叫小明");
String reply = assistant.chat("我叫什么？"); 
// 模型会回答"你叫小明"
```

`MessageWindowChatMemory` 是滑动窗口策略，保留最近 N 条消息，超了就丢最早的。简单粗暴但大部分场景够用。

还有 `TokenWindowChatMemory`，按 Token 数而不是消息条数来限制，适合需要精确控制上下文长度的场景。

## 和 Python 版 LangChain 对比

用了一段时间，聊聊我的感受。

**LangChain4j 的好处**：
- 类型安全，接口定义清晰，重构不怕
- AiServices 声明式调用很直观
- 和 Spring 生态集成顺畅
- 适合已有的 Java 企业项目

**Python LangChain 的好处**：
- 生态成熟，社区大，教程多
- 新功能出得快，AI 社区 Python 是绝对主流
- 原型验证快，Notebook 里写几行就能跑

其实吧，如果你的项目是 Java 栈，用 LangChain4j 很自然。不用为了接 AI 单独搞一个 Python 微服务，省事很多。但想快速试验 AI 想法的话，Python 还是更方便。

## 小结

LangChain4j 让 Java 开发者也能方便地接入大模型。核心就几个东西：ChatLanguageModel 负责对话，AiServices 做接口级抽象，ChatMemory 管理上下文记忆。掌握这三个就能覆盖大部分场景了。

我现在课程设计就在用 LangChain4j + Ollama 搞一个本地的智能问答系统，不花钱买 API，全在本地跑，挺有意思的。后面打算加 RAG，到时候再写一篇。

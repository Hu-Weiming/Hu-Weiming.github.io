---
title: "LangChain4j 初体验：Java 也能玩 LLM"
date: 2025-08-20
categories: ["AI"]
tags: ["AI", "LangChain4j", "Java"]
draft: true
---

# LangChain4j 初体验：Java 也能玩 LLM

## LangChain4j 是什么

说到 AI 开发，大家第一反应都是 Python。LangChain、LlamaIndex 清一色 Python。但我主力语言是 Java 啊，难道就只能干看着？

LangChain4j 填了这个坑。Java 版的 LangChain，提供了和 LLM 交互的各种工具：模型接入、Prompt 管理、Memory、RAG、Tools 调用等。

## 快速上手

建个 Spring Boot 项目，加上依赖：

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

几行代码调大模型。也可以接 Ollama 跑本地模型，不花钱：

```java
ChatLanguageModel model = OllamaChatModel.builder()
        .baseUrl("http://localhost:11434")
        .modelName("qwen2.5:7b")
        .build();
```

## ChatModel 的更多玩法

上面用的是最简单的字符串输入输出。实际开发中你需要更精细的控制。

LangChain4j 提供了 AiServices，把 LLM 调用包装成 Java 接口：

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

AiServices 是 LangChain4j 最好用的特性之一。定义接口，框架帮你搞定，很 Java 风格。

还能用 `@UserMessage` 搞 Prompt 模板：

```java
public interface Translator {
    @UserMessage("请将以下文本翻译成{{language}}：{{text}}")
    String translate(@V("text") String text, @V("language") String language);
}
```

调用 `translator.translate("Hello World", "中文")` 就行了。Prompt 模板化之后复用很方便。

## Memory：多轮对话

默认模型是无状态的，每次调用独立。想要多轮对话的"记忆"，需要把历史消息一起传给模型。

LangChain4j 提供了 ChatMemory：

```java
ChatMemory memory = MessageWindowChatMemory.withMaxMessages(20);

Assistant assistant = AiServices.builder(Assistant.class)
        .chatLanguageModel(model)
        .chatMemory(memory)
        .build();

assistant.chat("我叫小明");
String reply = assistant.chat("我叫什么？"); 
// "你叫小明"
```

`MessageWindowChatMemory` 是滑动窗口，保留最近 N 条消息，超了就丢最早的。简单粗暴但够用。

还有 `TokenWindowChatMemory`，按 Token 数限制，适合需要精确控制上下文长度的场景。

## 和 Python 版 LangChain 对比

用了一段时间，说说我的感受：

**LangChain4j 的优势**：
- 类型安全，Java 接口定义清晰，IDE 补全舒服
- AiServices 这种声明式调用比 Python 版的链式调用更直观
- 和 Spring 生态集成方便
- 适合企业级 Java 项目

**Python LangChain 的优势**：
- 生态更成熟，社区更大，教程多
- 新功能出得快，毕竟 AI 圈 Python 是主流
- 灵活性更强，原型开发快

说实话，如果你的项目是 Java 栈，用 LangChain4j 是很自然的选择。不用为了接 AI 再引入一个 Python 服务，简单很多。

但如果你是想快速试验各种 AI 想法，Python 还是更方便。毕竟 Jupyter Notebook 里写几行代码就能跑，Java 还得建项目、加依赖、写 main 方法……

## 小结

LangChain4j 让 Java 开发者也能很方便地接入大模型。核心就几个东西：ChatLanguageModel 负责对话，AiServices 做接口抽象，ChatMemory 管理上下文。掌握这三个就能覆盖大部分场景了。

我现在做课程设计就在用 LangChain4j + Ollama 搞一个本地的智能问答系统。不用花钱买 API，全在本地跑，挺有意思的。后面 RAG 那篇再展开说。

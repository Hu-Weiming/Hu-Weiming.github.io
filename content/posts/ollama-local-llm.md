---
title: "用 Ollama 在本地跑大模型，真的可以"
date: 2025-12-05
categories: ["AI"]
tags: ["AI", "Ollama", "本地部署"]
draft: true
---

# 用 Ollama 在本地跑大模型，真的可以

## Ollama 是什么

一直觉得跑大模型得有好几块 A100 才行，直到有人跟我说"试试 Ollama"。

Ollama 就是一个本地跑大模型的工具。一行命令安装，一行命令拉模型，一行命令运行。像 Docker 管容器一样管��� LLM。

支持 Mac、Linux、Windows，对 Apple Silicon 的 Mac 支持特别好。

## 安装和基本使用

Mac：

```bash
brew install ollama
```

启动服务后拉个模型：

```bash
ollama serve
ollama pull qwen2.5:7b
ollama run qwen2.5:7b
```

就可以在终端聊天了。第一次跑通的时候我挺惊���的——自己电脑上跑 AI，真可以。

M2 MacBook Pro 16GB 跑 7B 模型速度还行，基本实时对话。

## 常用模型推荐

Ollama 支持的模型很多，说几个我试过的：

- **qwen2.5:7b**��通义千问，中文效果好，7B 大小跑起来不吃力
- **llama3.1:8b**：Meta 的 Llama 3.1，英文强，中文也还行
- **codellama:7b**：专门写代码的，做代码补全不错
- **mistral:7b**：法国 Mistral AI 出的，小而精

管理模型的命令：

```bash
ollama list          # 查看已下载的模型
ollama pull llama3.1 # 下载模型
ollama rm mistral    # 删除模型
ollama show qwen2.5  # 查��模型信息
```

## API 调用

Ollama 启动后默认在 `localhost:11434` 提供 API，兼容 OpenAI 的接口格式。

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "qwen2.5:7b",
  "messages": [{"role": "user", "content": "什么是 Spring Boot？"}],
  "stream": false
}'
```

因为兼容 OpenAI 格式，很多现有的工具和库可以无缝接入，只需要把 base URL 改成 Ollama 的地址就行。

## 和 Java 集成

在 LangChain4j 里接 Ollama 特别简单：

```xml
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-ollama</artifactId>
    <version>0.35.0</version>
</dependency>
```

```java
ChatLanguageModel model = OllamaChatModel.builder()
        .baseUrl("http://localhost:11434")
        .modelName("qwen2.5:7b")
        .build();

String reply = model.generate("用 Java 写一个快速排序");
```

开发阶段用 Ollama 跑本地模型，不花钱。上线再切到 OpenAI 或其他 API。代码改动很小，换个 Model 实现��行。

## 各模型显存需求对比

TODO

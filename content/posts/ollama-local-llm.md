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

Ollama 是一个本地跑大模型的工具。一行命令安装，一行命令拉模型，一行命令运行。像 Docker 管容器一样管理 LLM，上手极快。

支持 Mac、Linux、Windows。对 Apple Silicon 的 Mac 支持特别好，能用统一内存跑模型。

## 安装和上手

Mac 安装：

```bash
brew install ollama
```

启动后拉个模型跑起来：

```bash
ollama serve
ollama pull qwen2.5:7b
ollama run qwen2.5:7b
```

在终端就能直接对话了。第一次跑通的时候我确实挺惊讶——自己笔记本就能跑 AI。

## 常用模型推荐

说几个我试过的：

- **qwen2.5:7b**：通义千问，中文效果好，7B 跑起来不吃力
- **llama3.1:8b**：Meta 出品，英文强，中文也还行
- **codellama:7b**：专门用来写代码的
- **mistral:7b**：法国 Mistral AI 的，小而精

管理命令：

```bash
ollama list          # 已下载的模型
ollama pull llama3.1 # 下载
ollama rm mistral    # 删除
ollama show qwen2.5  # 查看信息
```

## API 调用

Ollama 默认在 `localhost:11434` 提供 REST API，兼容 OpenAI 格式。

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "qwen2.5:7b",
  "messages": [{"role": "user", "content": "什么是 Spring Boot？"}],
  "stream": false
}'
```

兼容 OpenAI 格式意味着很多现有工具可以无缝切换，改个 URL 就行。

## 和 Java 集成

LangChain4j 接 Ollama 很简单：

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

开发阶段用 Ollama 本地模型不花钱，上线切到云端 API，代码改动很小。这个开发体验还是不错的。

## 显存需求对比

这个是大家最关心的——我的电脑能跑什么模型？

粗略的参考：

| 模型大小 | 最低内存/显存 | 推荐内存/显存 | 适合设备 |
|---------|------------|------------|---------|
| 1-3B | 4GB | 8GB | 轻薄本 |
| 7-8B | 8GB | 16GB | 普通笔记本 |
| 13-14B | 16GB | 32GB | 高配笔记本/台式机 |
| 30-34B | 32GB | 64GB | 高配台式机 |
| 70B | 64GB+ | 128GB+ | 服务器/多卡 |

注意这里说的是量化后的模型（一般是 Q4 量化）。量化会损失一点精度，但大幅降低内存需求。Ollama 默认就是拉量化版本。

我的 M2 MacBook Pro 16GB 内存：
- 7B 模型跑起来很流畅，推理速度大概 20-30 token/s
- 13B 勉强能跑，但速度明显慢，偶尔还会卡
- 更大的模型就别想了

如果你有独立显卡，Ollama 也支持 NVIDIA GPU 加速（需要 CUDA）。同样大小的模型，GPU 跑比 CPU 快好几倍。

顺便提一下，模型大小不完全决定效果。Qwen2.5 的 7B 在中文任务上的表现，不一定比 Llama 的 13B 差。选模型要看你的具体需求。

其实吧，现在本地跑大模型的门槛已经很低了。有台 16GB 内存的电脑就能玩。虽然效果比不上 GPT-4 或者 Claude，但拿来学习、做实验、写小工具完全够用了。而且不花钱不限量，想怎么折腾怎么折腾。

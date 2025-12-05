---
title: "用 Ollama 在本地跑大模型，真的可以"
date: 2025-12-05
categories: ["AI"]
tags: ["AI", "Ollama", "本地部署"]
draft: false
---

# 用 Ollama 在本地跑大模型，真的可以

## Ollama 是什么

一直觉得跑大模型得有好几块 A100 才行，直到有人跟我说"试试 Ollama"。

Ollama 是一个在本地运行大模型的工具。一行命令安装，一行命令拉模型，一行命令跑起来。它管理 LLM 的方式跟 Docker 管容器一样简单，上手极快。

Mac、Linux、Windows 都支持。对 Apple Silicon 的 Mac 支持特别好，能利用统一内存来跑模型。

## 安装和上手

Mac 上安装：

```bash
brew install ollama
```

也可以去官网 ollama.com 下安装包。启动服务后拉个模型试试：

```bash
ollama serve
ollama pull qwen2.5:7b
ollama run qwen2.5:7b
```

就可以在终端直接跟模型聊天了。第一次跑通的时候我确实挺惊讶——自己笔记本就能跑 AI，不用花一分钱。

## 推荐几个模型

Ollama 上可选的模型很多，说几个我试过觉得不错的：

- **qwen2.5:7b**：通义千问，中文效果好，7B 大小在普通笔记本上跑得动
- **llama3.1:8b**：Meta 出品，英文能力强，中文也还行
- **codellama:7b**：专门做代码生成和补全的，写 Java 还不错
- **mistral:7b**：法国 Mistral AI 的模型，综合性能不错

常用管理命令：

```bash
ollama list          # 查看已下载的模型
ollama pull llama3.1 # 下载模型
ollama rm mistral    # 删除模型
ollama show qwen2.5  # 查看模型详细信息
```

## API 调用

Ollama 启动后默认在 `localhost:11434` 提供 REST API，而且兼容 OpenAI 的接口格式。

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "qwen2.5:7b",
  "messages": [{"role": "user", "content": "什么是 Spring Boot？"}],
  "stream": false
}'
```

兼容 OpenAI 格式这点很关键——很多现有工具和 SDK 只需要改个 base URL 就能接入，迁移成本极低。

## 和 Java 集成

用 LangChain4j 接 Ollama 特别方便：

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

开发和测试阶段用 Ollama 本地模型，不花钱。上线切到 OpenAI 或其他云端 API，代码只需要换个 Model 实现。这个开发体验很舒服。

## 我的电脑能跑什么模型？

这个大家最关心。粗略的参考（量化后，Q4）：

| 模型大小 | 最低内存/显存 | 推荐配置 | 适合设备 |
|---------|------------|---------|---------|
| 1-3B | 4GB | 8GB | 轻薄本 |
| 7-8B | 8GB | 16GB | 普通笔记本 |
| 13-14B | 16GB | 32GB | 高配笔记本 |
| 30-34B | 32GB | 64GB | 高配台式机 |
| 70B | 64GB+ | 128GB+ | 服务器/多卡 |

Ollama 拉下来的默认就是量化版本，会损失一点精度但大幅降低内存需求。

我的 M2 MacBook Pro 16GB 实测：
- 7B 模型很流畅，推理速度约 20-30 token/s
- 13B 勉强能跑，速度明显慢，偶尔卡顿
- 再大的就别想了

有 NVIDIA 独显的话，Ollama 支持 GPU 加速（需要 CUDA），同样的模型跑起来快好几倍。

顺便说一句，模型参数量不完全决定效果。Qwen2.5 的 7B 在中文任务上，不见得比 Llama 的 13B 差。选模型还是得看具体需求。

其实吧，现在本地跑大模型门槛已经很低了。16GB 内存的电脑就能玩起来。效果虽然比不上 GPT-4 或 Claude，但拿来学习实验、写小工具完全够用。不花钱不限量，想怎么折腾怎么折腾，我觉得这才是学习 AI 最好的方式。

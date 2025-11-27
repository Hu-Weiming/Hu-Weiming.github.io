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

Ollama 就是一个本地运行大模型的工具。一行命令安装，一行命令拉模型，一行命令跑起来。像 Docker 一样简单，只不过它跑的是 LLM。

支持 Mac、Linux、Windows，对 Apple Silicon 的 Mac 支持特别好，能利用统一内存。

## 安装和基本使用

Mac 上安装：

```bash
brew install ollama
```

或者去官网 ollama.com 下安装包。安装完启动服务：

```bash
ollama serve
```

然后拉一个模型试试：

```bash
ollama pull qwen2.5:7b
```

跑起来：

```bash
ollama run qwen2.5:7b
```

然后你就可以在终端里跟大模型聊天了。第一次跑通的时候我还挺惊讶的——在自己电脑上跑 AI，还真可以。

响应速度跟你的硬件有关。我的 M2 MacBook Pro 16GB 跑 7B 模型，速度还不错，基本能做到实时对话。

## 拉取模型和对话

TODO

## API 调用

TODO

## 和 Java 集成

TODO

## 各模型显存需求对比

TODO

---
title: "大模型入门：到底什么是 LLM"
date: 2025-06-10
categories: ["AI"]
tags: ["AI", "LLM", "入门"]
draft: true
---

# 大模型入门：到底什么是 LLM

## Transformer 到底是什么

最近到处都在聊大模型、AI，感觉不了解点 LLM 都不好意思说自己学计算机的。但说实话，一开始我也是一头雾水。GPT、Transformer、Token 这些词到处飞，搜了好多资料才慢慢理清楚。

LLM，Large Language Model，大语言模型。说白了就是一个超大的神经网络，通过海量文本训练出来，学会了"语言"这件事。你给它一段文字，它能接着往下写——本质上就是在做下一个 Token 的预测。

那它用的什么架构呢？Transformer。2017 年 Google 的那篇"Attention is All You Need"论文提出的。

![Transformer 架构](https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/The-Transformer-model-architecture.png/440px-The-Transformer-model-architecture.png)

Transformer 的核心是注意力机制（Attention）。不用搞懂全部数学细节，你可以这么理解：模型在处理一个词的时候，会"看"整个句子里的其他词，判断哪些词跟当前这个词关系更密切。比如"我去银行取钱"，处理"银行"这个词时，模型会注意到"取钱"，从而理解这里的银行是金融机构而不是河岸。

之前的 RNN/LSTM 是按顺序处理文本的，一个词一个词来，处理长文本很慢。Transformer 可以并行处理，效率高很多，这也是为什么大模型能做这么大。

## 预训练和微调

大模型的训练分两个阶段。

**预训练（Pre-training）**：拿海量的文本数据（网页、书籍、代码、论文等），让模型学习语言的统计规律。这一步的目标很简单——预测下一个词。但就是这么简单的任务，在足够多的数据和足够大的模型上，居然涌现出了各种神奇的能力。

**微调（Fine-tuning）**：预训练完的模型像一个"什么都懂一点但不听话"的助手。微调就是进一步训练，让它更符合人类期望。常用的方法是 RLHF（基于人类反馈的强化学习）——人类标注员给模型的回答打分，模型根据打分调整自己。

ChatGPT 之所以好用，很大一部分功劳在微调阶段。没微调的模型（base model），你问它问题它可能不会好好回答，而是继续"接龙"。

## Token 和上下文窗口

TODO

## 常见模型对比

TODO

## 大模型能干什么不能干什么

TODO

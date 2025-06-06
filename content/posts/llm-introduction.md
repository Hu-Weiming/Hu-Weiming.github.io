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

那底层架构是什么？Transformer。2017 年 Google 那篇"Attention is All You Need"提出的。

![Transformer 架构](https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/The-Transformer-model-architecture.png/440px-The-Transformer-model-architecture.png)

Transformer 的核心是注意力机制（Attention）。不用搞懂数学细节，你可以这么理解：模型处理一个词的时候，会"看"句子里的其他词，判断谁跟它关系更密切。比如"我去银行取钱"，处理"银行"时模型会注意到"取钱"，从而知道这里是金融机构不是河岸。

之前的 RNN/LSTM 是按顺序一个词一个词处理的，长文本很慢。Transformer 可以并行处理，效率高很多，这也是大模型能做到这么大的关键。

## 预训练和微调

大模型的训练分两个阶段。

**预训练**：拿海量文本（网页、书籍、代码、论文），让模型学习语言的统计规律。目标就是预测下一个词。这么简单的任务，在足够多的数据和足够大的模型上，居然涌现出了各种能力，挺神奇的。

**微调**：预训练完的模型像一个"什么都懂一点但不听话"的人。微调让它更符合人类期望。常用的方法是 RLHF（基于人类反馈的强化学习）——人类给模型的回答打分，模型根据反馈调整。

ChatGPT 好用，很大功劳在微调。没微调的 base model，你问它问题它可能不好好回答，而是继续"接龙"。

## Token 和上下文窗口

大模型不是按"字"或"词"处理文本的，而是按 Token。一个 Token 大概对应一个常见的词或者子词。英文里一个单词通常是 1-2 个 Token，中文一个字大概 1-2 个 Token。

上下文窗口（Context Window）就是模型一次能处理的最大 Token 数。早期 GPT-3.5 是 4K，后来 GPT-4 到了 128K，Claude 现在支持到 200K。

为什么上下文窗口这么重要？因为模型只能"看到"窗口内的内容。你跟它聊天聊了很久，早期的对话可能已经被"忘掉"了——超出窗口了。

Token 数也直接关系到成本。API 调用是按 Token 收费的，input 和 output 分开计价。所以写 Prompt 的时候别废话太多，省钱。

## 常见模型对比

现在主流的大模型，简单聊聊：

**GPT 系列**（OpenAI）：GPT-4 / GPT-4o，综合能力很强。API 收费，国内访问需要点手段。

**Claude 系列**（Anthropic）：Claude 3.5 Sonnet / Claude 4，长文本处理很强，写代码也不错。上下文窗口很大。

**Llama 系列**（Meta）：开源的，Llama 3 出来之后效果很好。可以本地部署，适合研究和二次开发。

**Qwen 系列**（阿里通义）：国产开源模型里比较能打的。Qwen2.5 各个尺寸都有，7B 的小模型本地也能跑。

我个人的感受：日常用 GPT 或 Claude 都很好。想折腾本地部署就用 Llama 或 Qwen。选模型主要看你的场景和预算。

## 大模型能干什么不能干什么

TODO

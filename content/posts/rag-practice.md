---
title: "RAG 检索增强生成，让大模型不再胡说八道"
date: 2025-10-15
categories: ["AI"]
tags: ["AI", "RAG", "向量数据库"]
draft: true
---

# RAG 检索增强生成，让大模型不再胡说八道

## RAG 是什么

RAG，Retrieval-Augmented Generation，检索增强生成。名字唬人，思路简单：先从知识库里检索相关内容，把检索结果塞进 Prompt 给大模型，让模型基于这些内容回答。

大白话就是：开卷考试。模型自己不一定记得答案，但你给它参考资料，它就能答得靠谱。

## 为什么需要 RAG

大模型天然有几个限制：

1. **知识截止日期**：你公司文档、最新数据它不知道
2. **幻觉问题**：会编造看起来合理但错误的内容
3. **微调成本高**：要 GPU、数据集、门槛不低

RAG 不用微调模型，知识库更新了改文档就行。回答有据可查，成本也低。

我做课设想搞基于学校课程文档的问答系统。一开始想微调，太折腾。后来用 RAG，效果不错。

## 文档切分

第一步是把文档切成小块（Chunk）。模型上下文窗口有限，你不可能把整个文档塞进去。检索粒度越小越精准。

切分策略：
- 按字符数切——简单但可能切到句子中间
- 按段落切——保持语义完整
- 递归切分——先按大段切，太长再细分

一般 chunk size 在 200-1000 Token 之间，太小信息不完整，太大检索不准。加 overlap（重叠），比如每块重叠 50 Token，防止信息被切断。

```java
DocumentSplitter splitter = DocumentSplitters.recursive(500, 50);
List<TextSegment> segments = splitter.split(document);
```

## Embedding 和向量检索

怎么从一堆 Chunk 里找跟问题相关的？用向量检索。

Embedding 模型把文本转成高维向量（比如 1536 维的数组），语义相近的文本向量也接近。

流程：
1. 所有 Chunk 转向量，存到向量数据库
2. 用户提问转向量
3. 向量数据库里找最相似的 K 个 Chunk
4. 这些 Chunk 加用户问题一起给 LLM

向量数据库选择很多：Milvus、Qdrant、Chroma。轻量级的用内存就行。

```java
EmbeddingModel embeddingModel = OpenAiEmbeddingModel.builder()
        .apiKey("your-key")
        .modelName("text-embedding-3-small")
        .build();

InMemoryEmbeddingStore<TextSegment> embeddingStore = new InMemoryEmbeddingStore<>();
EmbeddingStoreIngestor ingestor = EmbeddingStoreIngestor.builder()
        .embeddingModel(embeddingModel)
        .embeddingStore(embeddingStore)
        .documentSplitter(DocumentSplitters.recursive(500, 50))
        .build();
ingestor.ingest(document);
```

## 用 LangChain4j 实现完整 RAG

前面的步骤准备好了，把 RAG 串起来其实就几行代码：

```java
ContentRetriever retriever = EmbeddingStoreContentRetriever.builder()
        .embeddingStore(embeddingStore)
        .embeddingModel(embeddingModel)
        .maxResults(3)
        .minScore(0.7)
        .build();

interface Assistant {
    @SystemMessage("基于以下参考资料回答用户问题，如果资料中没有相关信息就说不知道")
    String chat(String question);
}

Assistant assistant = AiServices.builder(Assistant.class)
        .chatLanguageModel(chatModel)
        .contentRetriever(retriever)
        .build();

String answer = assistant.chat("期末考试范围是什么？");
```

`maxResults(3)` 表示最多检索 3 个相关文档块，`minScore(0.7)` 设了相似度阈值，太不相关的就不要了。

LangChain4j 会自动把检索到的内容拼到 Prompt 里传给模型。你不用手动拼接，框架帮你搞定。

## 效果和踩坑

实际用下来，分享几个经验：

**切分粒度很重要**。我一开始 chunk size 设了 1000，检索效果不好，很多无关内容也被匹配到了。后来改成 300 加 50 overlap，效果明显提升。

**Embedding 模型的选择影响很大**。OpenAI 的 text-embedding-3-small 对中文支持还行，但不如专门针对中文优化的模型。如果文档是中文的，可以考虑用 bge-large-zh 这类中文 Embedding 模型。

**Prompt 里要告诉模型"不知道就说不知道"**。不然模型检索不到相关内容的时候还是会编造答案，RAG 就白搭了。

**向量数据库选型**。数据量小（几千条）用内存就行。数据量大了得上 Milvus 或者 Qdrant，不然检索速度受不了。

说到这里，RAG 是目前让大模型结合私有知识最实用的方案。虽然也有局限（比如检索不到的信息还是答不了），但对大部分场景来说够用了。比起微调，性价比高多了。

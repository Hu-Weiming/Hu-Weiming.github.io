---
title: "RAG 检索增强生成，让大模型不再胡说八道"
date: 2025-10-15
categories: ["AI"]
tags: ["AI", "RAG", "向量数据库"]
draft: true
---

# RAG 检索增强生成，让大模型不再胡说八道

## RAG 是什么

RAG，Retrieval-Augmented Generation，检索增强生成。名字唬人，思路很简单：先从知识库里检索相关内容，然后把检索结果塞进 Prompt 一起给大模型，让模型基于这些内容来回答。

大白话说就是：开卷考试。模型自己不一定记得答案，但你把参考资料给它，它就能答得靠谱了。

## 为什么需要 RAG

大模型有几个天然的限制：

1. **知识有截止日期**：你公司的文档、最新的数据它不知道
2. **会胡说八道**（幻觉）：编造看起来合理但实际错误的内容
3. **微调成本高**：想让模型学私有数据？要 GPU、要数据集、门槛不低

RAG 的好处是不用微调模型，知识库更新了改文档就行。回答有据可查，实现成本也低。

我做课设想搞个基于学校课程文档的问答系统。一开始想微调，太折腾了。后来用 RAG，简单多了，效果也不错。

## 文档切分

RAG 的第一步是把你的文档切成小块（Chunk）。为什么要切？因为模型上下文窗口有限，你不可能把整个文档都塞进去。而且检索的粒度越小，越精准。

切分策略很有讲究：
- **按字符数切**：简单但可能切到句子中间
- **按段落切**：保持语义完整性
- **递归切分**：先按大段切，太长的再细分
- **按句子切**：粒度最细

一般推荐 chunk size 在 200-1000 个 Token 之间，太小了信息不完整，太大了检索不精准。还要加 overlap（重叠），比如每块重叠 50 个 Token，防止重要信息被切断。

```java
DocumentSplitter splitter = DocumentSplitters.recursive(500, 50);
List<TextSegment> segments = splitter.split(document);
```

## Embedding 和向量检索

切完之后，怎么从一堆 Chunk 里找到跟用户问题相关的？用向量检索。

Embedding 模型会把一段文本转成一个高维向量（比如 1536 维的浮点数数组）。语义相近的文本，向量也会接近。

流程是这样：
1. 把所有文档 Chunk 用 Embedding 模型转成向量，存到向量数据库
2. 用户提问时，把问题也转成向量
3. 在向量数据库里找最相似的 K 个 Chunk
4. 把这些 Chunk 和用户问题一起给 LLM

向量数据库现在选择很多：Milvus、Qdrant、Chroma、Pinecone。轻量级的话用内存存储就行，LangChain4j 自带了 `InMemoryEmbeddingStore`。

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

## 用 LangChain4j 实现 RAG

TODO

## 效果和踩坑

TODO

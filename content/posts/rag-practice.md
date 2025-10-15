---
title: "RAG 检索增强生成，让大模型不再胡说八道"
date: 2025-10-15
categories: ["AI"]
tags: ["AI", "RAG", "向量数据库"]
draft: false
---

# RAG 检索增强生成，让大模型不再胡说八道

## RAG 是什么

RAG，Retrieval-Augmented Generation，检索增强生成。名字挺唬人，但思路很简单：先从你自己的知识库里检索相关内容，把检索结果塞进 Prompt 里一起给大模型，让模型基于这些内容来回答。

用大白话说就是：给模型开卷考试。它自己可能不记得答案，但你给它参考资料，它就能答得靠谱了。

## 为什么需要 RAG

大模型天然有几个局限：

1. **知识有截止日期**：你公司的内部文档、最新的业务数据它不知道
2. **会胡说八道**（幻觉）：编造看起来合理但实际错误的内容
3. **微调成本高**：要 GPU、要标注数据、要调参，门槛不低

RAG 好在不用微调模型。知识库更新了？改文档重新索引就行。回答有据可查，实现成本也低。

我做课设想搞个基于学校课程文档的问答系统。一开始想微调，研究了半天发现太折腾了。后来改用 RAG 方案，效果还不错。

## 文档切分：第一步就有讲究

RAG 的第一步是把文档切成小块（Chunk）。为什么？模型上下文窗口有限，你不可能把整本书塞进去。而且检索粒度越小，匹配越精准。

常见切分策略：
- 按字符数切——简单但可能把句子切断
- 按段落切——保持语义完整
- 递归切分——先按大段切，太长的再往下拆

chunk size 一般设在 200-1000 Token 之间。太小信息不完整，太大检索不精准。记得加 overlap（重叠），比如每块重叠 50 Token，防止重要信息正好被切在边界上。

```java
DocumentSplitter splitter = DocumentSplitters.recursive(500, 50);
List<TextSegment> segments = splitter.split(document);
```

## Embedding 和向量检索

切完之后，怎么从一堆 Chunk 里找到跟用户问题相关的？答案是向量检索。

Embedding 模型会把文本转成一个高维向量（比如 1536 维的浮点数数组）。语义相近的文本，转出来的向量也会接近。

整个流程：
1. 把所有文档 Chunk 转成向量，存到向量数据库
2. 用户提问时，把问题也转成向量
3. 在向量数据库里找最相似的 K 个 Chunk
4. 把这些 Chunk 跟用户问题一起交给 LLM

向量数据库现在选择很多：Milvus、Qdrant、Chroma、Pinecone。数据量小的话用内存存储就够了。

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

前面的准备工作做好了，把 RAG 串起来其实没几行：

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

`maxResults(3)` 表示最多检索 3 个文档块，`minScore(0.7)` 设了相似度阈值，不够相关的就过滤掉。LangChain4j 会自动把检索到的内容拼到 Prompt 里，你不用手动拼接。

## 踩过的坑和经验

实际用下来几个教训：

**切分粒度很关键**。我一开始 chunk size 设了 1000，检索老是匹配到无关内容。改成 300 加 50 overlap 之后效果明显好了。这个参数得根据你的文档特点调。

**Embedding 模型选对很重要**。OpenAI 的 text-embedding-3-small 对中文支持还行，但如果文档全是中文，可以试试 bge-large-zh 这类专门为中文优化的模型，效果会好不少。

**系统提示词里一定要加"不知道就说不知道"**。不然检索不到相关内容的时候，模型照样编答案，RAG 就白搭了。

**向量数据库不用太纠结**。数据量几千条用内存足够，上万条再考虑 Milvus 或 Qdrant。别一上来就搞个分布式向量库，杀鸡焉用牛刀。

其实吧，RAG 是目前让大模型结合私有知识最实用的方案了。虽然也有局限——检索不到的信息还是答不了，但对大部分场景来说性价比很高，比微调划算多了。

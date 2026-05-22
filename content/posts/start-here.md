---
title: "从这里开始"
date: 2026-05-13T18:00:00+08:00
description: "博客重构后的第一篇示例文章，用来验证 Netlify 和 Decap CMS 的发布链路。"
categories:
  - b
tags:
  - Netlify
  - Decap CMS
draft: false
---

这是一篇示例文章。

如果你能在 Decap CMS 里看到它，说明后台已经能够读取 `content/posts` 目录。后面新建文章时，Decap 会把 Markdown 文件写入同一个目录，然后通过 Git Gateway 提交到 GitHub。

发布链路应该是：

1. 在 `/admin/` 登录。
2. 新建或编辑文章。
3. 保存并发布。
4. Netlify 收到 GitHub 更新后自动构建。

页面风格会继续保持极简，以白色为底，淡紫色只用于链接、分割和很轻的强调。

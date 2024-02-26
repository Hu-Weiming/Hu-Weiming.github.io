---
title: "MyBatis 一条 SQL 的执行之旅"
date: 2024-03-05
categories: ["框架"]
tags: ["Java", "MyBatis", "ORM"]
draft: true
---

# MyBatis 一条 SQL 的执行之旅

## 从 Mapper 接口说起

用 MyBatis 写代码，日常就是定义一个 Mapper 接口，写个 XML 或注解，然后调用方法就完事了。但你有没有想过，你调 `userMapper.selectById(1)` 的时候，MyBatis 背后到底干了啥？

我之前一直觉得这东西就是个黑盒，SQL 进去，对象出来，不用管。直到有次面试被问"说说 MyBatis 的执行流程"，我愣住了。回来之后认真翻了源码，发现这个流程其实挺清晰的。

简单说，你调 Mapper 方法，其实调的是一个 JDK 动态代理对象。MyBatis 在启动的时候会给每个 Mapper 接口生成代理，拦截方法调用，然后转到 SqlSession 去执行。

```java
// 你以为你在调接口方法
User user = userMapper.selectById(1);

// 实际上等价于
User user = sqlSession.selectOne("com.example.mapper.UserMapper.selectById", 1);
```

所以 Mapper 接口本身没有实现类，全靠代理。这个设计挺巧妙的，让你写代码的时候感觉像在调普通方法。

## SqlSession 是什么

SqlSession 是 MyBatis 的核心接口，相当于一次数据库会话。它提供了 selectOne、selectList、insert、update、delete 这些方法。

不过 SqlSession 自己不干活，它把事情委托给 Executor。你可以把 SqlSession 理解成一个门面，真正干活的是 Executor。

```java
public class DefaultSqlSession implements SqlSession {
    private final Executor executor;
    
    @Override
    public <T> T selectOne(String statement, Object parameter) {
        List<T> list = this.selectList(statement, parameter);
        if (list.size() == 1) {
            return list.get(0);
        }
        // ...
    }
}
```

话说回来，如果你用的是 Spring + MyBatis，SqlSession 的创建和关闭都被 SqlSessionTemplate 管了，你基本不用操心。

## Executor 执行器

TODO

## StatementHandler 和参数映射

TODO

## 结果集映射

TODO

## 一级缓存和二级缓存

TODO

## 总结

TODO

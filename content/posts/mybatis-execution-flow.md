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

Executor 是真正执行 SQL 的组件。MyBatis 有三种 Executor：

- **SimpleExecutor**：每次执行都创建新的 Statement
- **ReuseExecutor**：会复用 Statement
- **BatchExecutor**：批量执行，适合大量 insert/update

默认用的是 SimpleExecutor。Executor 拿到 MappedStatement（就是你 XML 里那条 SQL 的所有信息），然后交给 StatementHandler 去处理。

```java
// Executor 的核心方法
public <E> List<E> query(MappedStatement ms, Object parameter, 
                          RowBounds rowBounds, ResultHandler resultHandler) {
    BoundSql boundSql = ms.getBoundSql(parameter);
    CacheKey key = createCacheKey(ms, parameter, rowBounds, boundSql);
    return query(ms, parameter, rowBounds, resultHandler, key, boundSql);
}
```

注意这里有个 CacheKey，后面讲缓存会用到。

## StatementHandler 和参数映射

StatementHandler 负责创建 JDBC 的 Statement，设置参数，执行 SQL。

参数设置这块是 ParameterHandler 干的。它会把你传的 Java 对象映射成 SQL 的参数。这里用到了 TypeHandler，比如把 Java 的 String 映射成 VARCHAR，把 Date 映射成 TIMESTAMP。

```java
// ParameterHandler 设置参数
public void setParameters(PreparedStatement ps) {
    // 遍历参数映射
    for (int i = 0; i < parameterMappings.size(); i++) {
        ParameterMapping parameterMapping = parameterMappings.get(i);
        Object value = // 从参数对象中取值
        TypeHandler typeHandler = parameterMapping.getTypeHandler();
        typeHandler.setParameter(ps, i + 1, value, parameterMapping.getJdbcType());
    }
}
```

我之前踩过一个坑：参数是 Map 的时候，XML 里的 `#{key}` 要和 Map 的 key 对上，不然就是 null。debug 了半天才发现是 key 写错了，大小写不一致。

## 结果集映射

SQL 执行完，ResultSetHandler 负责把 JDBC 的 ResultSet 映射成 Java 对象。

这个过程大概是：
1. 根据 resultMap 或 resultType 确定目标类型
2. 创建目标对象（反射）
3. 遍历列，用 TypeHandler 把数据库类型转成 Java 类型
4. 通过反射设置属性值

如果你用了 resultMap 还配了 association 和 collection，那就涉及嵌套查询或嵌套结果集映射，逻辑会复杂不少。

顺便提一下，MyBatis 的自动映射（autoMapping）默认是开的，它会尝试把列名和属性名匹配。驼峰命名转换可以通过 `mapUnderscoreToCamelCase` 配置开启，这个基本是必开的。

## 一级缓存和二级缓存

TODO

## 总结

TODO

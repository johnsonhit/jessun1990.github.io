---
title: "Elastic 基本小结"
date:  2019-05-15
lastmod: 2019-09-02T01:15:47+08:00
draft: false
tags: ["golang", "elasticsearch", "es"]
categories: ["Code"]
author: "jessun"
weight: 1

# You can also close(false) or open(true) something for this content.
# P.S. comment can only be closed
# comment: false
# toc: false

# You can also define another contentCopyright. e.g. contentCopyright: "This is another copyright."
# contentCopyright: 'null'
# reward: false
# mathjax: true
---

# 1. 简介

> Elasticsearch 是一个基于 Lucene 库的搜索引擎。它提供了一个分布式、支持多租户的全文搜索引擎，具有 HTTP Web 接口和无模式JSON文档。Elasticsearch 是用 Java 开发的，并在 Apache 许可证下作为开源软件发布。（源引维基百科：[Elasticsearch](https://zh.wikipedia.org/wiki/Elasticsearch)）

**优势**

- 横向可扩展性：增加服务器可直接配置在集群中。
- 分片机制提供更好的分布性：分而治之的方式来提升处理效率。
- 高可用：提供复制（replica）机制
- 实时性：通过将磁盘上的文件放入文件缓存系统来提高查询速度

# 2. 基本概念

- **Index**: 一系列文档的集合，类似与 mysql 中数据库的概念。
- **Type**: 在 Index 里面可以定义不同的 type，type 的概念类似于 mysql 中表的概念，是一系列具有相同特征数据的结合。
- **Document**: 文档的概念类似于 mysql 中的一条存储记录，并且为 json 格式，在 Index 下的不同 type 下，可以有许多 document。
- **Shards**: 在数据量很大的时候，进行水平的扩展，提高搜索性能。
- **Replicas**: 防止某个分片的数据丢失，可以并行地在备份数据里的搜索提高性能。

# 3. ElasticSearch 查询语法

> 参考: [<< Elasticsearch: 权威指南 >>](https://www.elastic.co/guide/cn/elasticsearch/guide/current/index.html "语法参考")

## 3.1 Query 查询

### 3.1.1 获取 es 基本信息

    `GET xxx.xxx.xxx.xxx:9200`

    返回结果：

    ```json
    {
        "status" : 200,
        "name" : "search_server",
        "cluster_name" : "es01",
        "version" : {
            "number" : "1.5.2",
            "build_hash" : "${buildNumber}",
            "build_timestamp" : "2017-04-14T06:28:51Z",
            "build_snapshot" : false,
            "lucene_version" : "4.10.4"
        },
        "tagline" : "You Know, for Search"
    }
    ```

### 3.1.2 获取指定 id 的文档信息

    `GET xxx.xxx.xxx.xxx:9200/{index}/{type}/{id}`

    返回结果：

    ```json
    {
        "_index": "student",
        "_type": "default",
        "_id": "1",
        "_version": 3,
        "found": true,
        "_source": {
            "id": "1",
            "name": "张三",
            "company_id": 68,
            "user_id": 1000,
            "created_at": "2019-04-28T19: 59: 01.821525+08: 00"
        }
    }
    ```

### 3.1.3 Match query，符合 user_id 为 1000。如果是中文还会做分词。

    `GET xxx.xxx.xxx.xxx:9200/{index}/_search`

    返回结果

    ```json
    {
        "query": {
            "match": {
                "user_id": 1000
            }
        }
    }
    ```

### 3.1.4 Range query

    > 支持包含时间在内的范围查询

    `GET xxx.xxx.xxx.xxx:9200/{index}/_search`

    ```json
    {
        "query": {
            "range": {
                "created_at": {
                "gte":  1557761682,
                "lte":  1557771682
                }
            }
        }:
    }
    ```

### 3.1.5 Term query

    > term 查询被用于精确值匹配，这些精确值可能是**数字**、**时间**、**布尔**或者那些 not_analyzed 的字符串。term 查询对于输入的不做分析， 所以它将进行精确查询。

    ```json
    GET /_search
    {
        "query": {
            "term": {
                "company_id": 100
            }
        }
    }
    ```

### 3.1.6 Terms query

    > terms 查询和 term 查询一样，但它允许你指定多值进行匹配，如果这个字段包含了指定值中的任何一个值，那么这个文档就算是满足条件。

    ```json
    {
        "terms": {
            "company_id": [ 100, 101, 102 ]
        }
    }
    ```

## 3.2 Aggregation 聚合

Elasticsearch 有一个功能叫做聚合(aggregation)，可以在数据上生成复杂的分析统计，类似 SQL 中的 group by。

Aggregation 分为两种：

- Metrics, Metrics 是最简单的对过滤出来的数据集进行avg，max等操作，是一个单一的数值。
- Bucket, Bucket 则是将过滤出来的数据集分成多个小数据集，然后 Metrics 分别作用在这些小数据集上

Elasticsearch 从1.0开始支持 aggregation，基本上有了普通 SQL 的聚合能力。从2.0开始支持 pipline aggregaion，可以支持类似 SQL sub query 的嵌套聚合能力。
Metrics 既可以作用在整个数据集上，也可以作为 Bucket 的子聚合作用在每一个“桶”中的数据集上。

ES 中的聚合 API 的调用格式如下：

```shell
curl  -XGET 'xxx.xxx.xxx.xxx:9200/megacorp/employee/_search' -d
'
{
    "aggs": {                    // 固定字段名，也可以用 aggregations
        "all_interests": {       // 自定义名称
            "terms": {"field": "intersets"}
        }
    }
}
'
```

### 3.2.1 度量(Metric)聚合

#### 3.2.1.1 Min Aggregation

最小值查询，作用在 number 类型字段上。查询2班最小的年龄值。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?' -d
'{
    "query": {
        "term": {
            "class_no": 2
        }
    },
    "aggregation": {
        "min_age": {
            "min": {
                "field": "age"
            }
        }
    }
}'
```

返回结果

```json
{
    "took": 19,                     // 前面部分数据与普通的查询数据相同
        "timed_out": false,
        "_shards": {
            "total": 5,
            "successful": 5,
            "failed": 0
        },
        "hits": {
            "total": 3,
            "max_score": 1.4054651,
            "hits": [
            {
                "_index": "student",
                "_type": "student",
                "_id": "2",
                "_score": 1.4054651,
                "_source": {        // source 字段内容即是存入的数据
                    "studentNo": "2",
                    "name": "关羽",
                    "male": "男",
                    "age": "22",
                    "birthday": "1987-08-23",
                    "classNo": "2",
                    "isLeader": "false"
                }
            },
            {
                "_index": "student",
                "_type": "student",
                "_id": "8",
                "_score": 1,
                "_source": {
                    "studentNo": "8",
                    "name": "赵云",
                    "male": "男",
                    "age": "23",
                    "birthday": "1986-10-26",
                    "classNo": "2",
                    "isLeader": "false"
                }
            },
            {
                "_index": "student",
                "_type": "student",
                "_id": "5",
                "_score": 0.30685282,
                "_source": {
                    "studentNo": "5",
                    "name": "诸葛亮",
                    "male": "男",
                    "age": "18",
                    "birthday": "1992-04-27",
                    "classNo": "2",
                    "isLeader": "true"
                }
            }
            ]
        },
        "aggregations": {                      // 聚合结果
            "min_age": {                       // 前面输入的聚合名
                "value": 18,                   // 聚合后的数据
                "value_as_string": "18.0"
            }
        }
}
```

聚合查询，先通过 query 过滤数据，返回的结果会包含聚合操作所用的数据全集。
有时候我们对作用的数据全集并不太感兴趣，仅仅需要最终的聚合结果，可以通过查询类型（search_type）参数来实现这个需求。下面查询出来的数据量会大大减少，ES 内部也会在查询时减少一些耗时的查询，所以查询效率会提高。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/_search?search_type=count' -d
'
{
    "query": {
        "term": {
            "class_no": "2"
        }
    },
    "aggs": {
        "min_age": {
            "min": {
                "field": "age"
            }
        }
    }
}
'
```

返回结果：

```json
{
    ...
    "aggregations": {                   // 聚合结果
        "min_age": {                    // 前面输入的聚合名
            "value": 18,                // 聚合后的数据
            "value_as_string": "18.0"
        }
    }
}
```

#### 3.2.1.2 Max Aggregation

最大值查询。下面查询2班的最大的年龄值，查询结果为23。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/sutudent/_search?search_type=count' -d
'
{
    "query": {
        "term": {
            "class_no": "2"
        }
    },
    "aggs": {
        "max_age": {
            "max": {
                "field": "age"
            }
        }
    }
}
'
```

#### 3.2.1.3 Sum Aggregation

数值求和。下面统计查询2班的年龄总和，查询结果为63。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/sutudent/student/_search?search_type=count' -d
'
{
    "query": {
        "term": {
            "class_no": "2"
        }
    },
    "aggs": {
        "sum_age": {
            "sum": {
                "field": "age"
            }
        }
    }
}
'
```

#### 3.2.1.4 Avg Aggregation

计算平均值。下面计算查询2班的年龄平均值，结果为21。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'{
    "query": {
        "term": {
            "class_no": "2"
        }
    },
    "aggs": {
        ""
    },
    {
        "aggs": {
            "avg_age": {
                "avg": {
                    "filed" "age"
                }
            }
        }
    }
}'
```

#### 3.2.1.5 Stats Aggregation

统计查询，一次性统计出某个字段上的常用统计值。下面对整个学校的学生进行简单地统计

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/sutudent/_search?search_type=count' -d
'
{
    "aggs": {
        "stats_age": {
            "stats": {
                "field" : "age"
            }
        }
    '}
}
'
```

返回结果：

```json
{
    ...
    "aggregations":  {
        "stats_age": {
            "count": 8,
            "min": 16,
            "max": 24,
            "avg": 20.125,
            "sum": 161,
            "min_as_string": "16.0",
            "max_as_string": "24.0",
            "avg_as_string": "20.125",
            "sum_as_string": "161.0"
        }
    }
}
```

#### 3.2.1.6 Top Hists Aggregation

取出符合条件的前n条数据记录。下面查询全校年龄排在前2位的学生，仅需返回学生的姓名和年龄

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "top_age": {
            "top_hits": {
                "sort": [
                    {
                        "age": {
                        "order": "desc"
                        }
                    }
                ],
                "_source":{
                    "include": [
                        "name", "age"
                    ]
                },
                "size": 2
            }
        }
    }
}
'

返回结果：


```json
{
    "aggregations": {
    "top_age": {
      "hits": {
        "total": 9,
        "max_score": null,
        "hits": [
          {
            "_index": "student",
            "_type": "student",
            "_id": "1",
            "_score": null,
            "_source": {
              "name": "刘备",
              "age": "24"
            },
            "sort": [
              24
            ]
          },
          {
            "_index": "student",
            "_type": "student",
            "_id": "8",
            "_score": null,
            "_source": {
              "name": "赵云",
              "age": "23"
            },
            "sort": [
              23
            ]
          }
        ]
      }
    }
  }
}
```

#### 3.2.2 桶类型（Bucket）聚合

#### 3.2.2.1 Terms Aggregation

按照指定的一个或者多个字段将数据划分成若干个小的区间，计算落在每一个区间上记录的数量，并按指定顺序进行排序。下面按照每个班的学生数，并按照学生数从小到大进行排序，取学生数靠前的2个班级。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "terms_class_no": {
            "terms": {
                "field": "class_no",      // 按照班号进行分组
                "order": {               // 按照学生数从大到小排序
                    "_count": "desc"
                },
                "size": 2
            }
        }
    }
}
'
```

> 值得注意的是，结果是一个近似值，这和 ES 的[实现方式](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html)有关。如果想要去的精确值，需要自行进行全量排序（也就是移除 Size 字段），然后“手动”取前两条记录。当然，这样使得 ES 的效率非常低

#### 3.2.2.2 Range Aggregation

自定义的范围聚合，可以按照指定的范围划分区间对数据进行分组统计。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "range_age": {
            "range": [
                "field": "age",
            "ranges": [
                {"to": 15},
                {"from": 16, "to": 18},
                {"from": 19, "to": 21},
                {"from": 22, "to": 24},
                {"from": "25"}
            ]
            ]
        }
    }
}
'
```

#### 3.2.2.3 Date Range Aggregation

时间区间聚合专门针对date类型的字段，它与Range Aggregation的主要区别是其可以使用时间运算表达式。主要包括+（加法）运算、-（减法）运算和/（四舍五入）运算，每种运算都可以作用在不同的时间域上面，下面是一些时间运算表达式示例。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "range_age": {
            "date_range": {
                "field": "birthday",
                "range": [
                    {
                        "to": "now-25y"
                    }
                ]
            }
        }
    }
}
'
```

#### 3.2.2.4 Histogram Aggregation

直方图聚合。将某个类型字段等分成 n 份，统计落在每一个区间的记录数，和 Range 聚合非常像。 Range 聚合可以任意划分区间，而 Histogram 做等距划分。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "histogram_age": {
            "hisgogram": {
                "field": "age",
                "interval": 2,            // 返回各年龄段内的学生数量
                "min_doc_count": 1        // 只返回记录数量大于1的区间
            }
        }
    }
}
'
```

#### 3.2.2.5 Date Histogram Aggregation

时间直方图聚合。专门针对时间类型的字段做直方图聚合，可以按照固定的时间段进行统计。

```shell
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "date_histogram_birthday": {
            "date_histogram": {
                "field": "birthday",
                "interval": "year",       // 按年统计
                "format": "yyyy"          // 返回结果的 key 的格式
            }
        }
    }
}
'
```

获得的结果如下，由于指定了 format 字段，所以 key_as_string 只返回了年的信息

```json
{
    "buckets": [
        {
            "key_as_string": "1985",
            "key": 473385600000,
            "doc_count": 1
        },{
            "key_as_string": "1986",
            "key": 504921600000,
            "doc_count": 1
        }
        ......
    ]
}
```

#### 3.2.2.6 Missing Aggregation

值缺损聚合，单桶聚合。最终只会产生一个“桶”。下面统计学生信息中地址栏缺损的记录数量。

```json
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "missing_address": {
            "missing": {
                "field": "address"
            }
        }
    }
}
'
```

### 嵌套使用

```json
curl -XPOST 'xxx.xxx.xxx.xxx:9200/student/student/_search?search_type=count' -d
'
{
    "aggs": {
        "missing_address": {
            "terms": {
                "field": "class_no"
            },
            "aggs": {                // 一个子聚合
                "max_age": {
                    "max": {
                        "field": "age"
                    }
                }
            }
        }
    }
}
'
```

获得的结果：

```shell
{
    "buckets": [
        {
            "key": "1",
            "doc_count": 3,
            "max_age": {
                "value": 24,
                "value_as_string": "24.0"
            }
        },
        {
            "key": "2",
            "doc_count": 3,
            "max_age": {
                "value": 23,
                "value_as_string": "23.0"
            }
        },
        {
            "key": "3",
            "doc_count": 1,
            "max_age": {
                "value": 20,
                "value_as_string": "20.0"
            }
        },
        {
            "key": "4",
            "doc_count": 1,
            "max_age": {
                "value": 16,
                "value_as_string": "16.0"
            }
        }
    ]
}
```

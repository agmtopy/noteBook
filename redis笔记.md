### Redis笔记

#### Redis基本数据结构

序号|名称|-
--|--|--
1|string|字符串
2|list|列表
3|set|集合
4|zset|有序集合
5|hash|哈希

##### string
 结构 key --> "String value"
 底层存储方式是通过存储动态可修改的的字符串,会预分配冗余空间,当对象小于1M时成倍进行扩容,当对象大于1M时,每次扩容增长1M.字符串的最大大小为512M.

 操作

 序号|命令|含义
 --|--|--
 1|set key value|写入数据
 2|get key|获取数据
 3|exists key\|key...|判断健值是否存在
 4|del key\|key...|删除健值对
 5|mget key\|key..|批量获取值
 6|mset key value\|key value...|批量设置值
 7|expire key seconds|设置键值的过期时间
 8|setex key seconds value| 等价于set expire
 

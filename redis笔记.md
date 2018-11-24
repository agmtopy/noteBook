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
 当value为一个整数时,可以对它进行自增操作,它的范围为signed long的范围.

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
 9|setnx key value|存在key,就写入失败,不覆盖
10|incr key|对value进行自增操作
11|incrby key increment|对key增加 increment

#### list

redis中的列表相当于linedlist(链表结构),常用来作为异步队列,一个线程将任务结构体序列化成string push到队列中,另外一个线程进行读取.支持FIFO/FILO,底层存储结构,在数据量较小的时候采用ziplist(压缩列表,内存中连续分配一块区域)，当数据量较大时采用quicklist(用双向链表将ziplist串联起来)

操作

 序号|命令|含义
 --|--|--
1|rpush key value\|value... |设置list值
2|llen key| list的长度
3|lpop key|FIFO
4|rpop key|FILO
5|lindex key index|获取指定位置的值
6|ltrim key start end|截取list
7|lrange key start end|返回指定范围的值

#### hash
 redis的hash相当于java中的HashMap,底层结构与HashMap实现方式一致,redis的hash在进行rehash时,为保证高性能,采用渐进式rehash的策略.只能存储字符串.

 操作
 序号|命令|含义
 --|--|--
 1|hset key field value|向hash集合中set元素
 2|hgetall key|获取指定hash集合的全部值
 3|hlen key|获取hash的长度
 4|hget key field|获取指定hash的属性值
 5|hmset key field\|filed value...|批量设置field的值
 6|hmget key field\|filed ...|批量获取filed的值
 7|hincrby key field increment|设置属性值自增

 #### set
   set内部无序且唯一的键值结构

操作
 序号|命令|含义
 --|--|--
 1|sadd key member\|member...|设置元素
 2|smembers key|获取全部元素
 3|sismember key member|判断指定set集合中是否存在元素
 4|scard key|获取set的长度
 5|spop key|弹出一个元素

#### zset
 zset 是内部有序的set集合,为每一个value赋予一个score的排序权重.底层采用跳跃列表的数据结构进行存储.
  
  操作
序号|命令|含义
 --|--|--
 1|zadd key score value \|key score value ...|装载元素
 2|zrange key|顺序弹出
 3|zrevrange key|逆序弹出
 4|zcard key|统计条数
 5|zrangebyscore key statr end|获取指定范围内的值
 6|zrem key value|删除指定的value
 
 #### 容器的通用规则
  1. create if not exists 不存在就创建
  2. drop is not elements 没有元素就回收集合释放内存

  - 存储结构体用string还是hash?
   string:
   1.在访问中使用到了大部分字段
   2.某些属性不同
   hash
   1.在访问中总是只用到几个字段
   2.知道那些字段是可用的

   ---------------------------------------------

### 应用   

#### 分布式锁

分布式锁本质上是在redis中占用一个资源,当别的进程要来获取资源时候,只能放弃或阻塞.

操作
序号|命令|含义
--|--|--
1|setnx key true|设置锁
2|del key|删除锁
3|expire key seconds |设置锁的过期时间
4|set key value [EX seconds] [PX millisenconds] [NX|EX] |将setnx和expire命令合二为一


#### 延时队列

redis可以用list结构来作为异步延时队列,使用rpush/lpush插入队列,使用lpop/rpop来弹出队列.使用blpop/brpop来进行阻塞读,

#### 位图

位图底层采用的是普通的byte数组,可以使用普通的get/set来直接获取和操作整个位图的内容,也可以通过getbit/setbit来将byte数组看成位数组来处理.

操作
序号|命令|含义
--|--|--
1|getbit key offset|获取指定byte数组index位置上的值
2|setbit key offset value|设置byte数组指定位置上的值
3|bitcount key [start end]|统计指定范围内1的个数
4|bitpos key bit[start end]|统计指定范围内0的个数

#### HyperLogLog
 HyperLogLog提供不精确的去重方案,是redis的高级数据结构.

操作
序号|命令|含义
--|--|--
1|pfadd key element\|element ...|设置元素
2|pfcount key|统计key


#### 布隆过滤器
 底层通过计算多个均匀hash函数的值来保存对象的指纹,通过指纹来判断该元素是否存在.

 #### 简单限流
 通过zset的超时过期的策略来维护一个在单位时间内失效的key,在应用层判断是否操作最大maxcount,来判断结果，从而进行业务上的操作.

#### 漏斗限流
通过redis-cell实现的一种限流策略

#### GeoHash
基于GeoHash地理位置距离排序算法的set集合,提供一系列操作来实现geo功能

#### Scan
redis运维管理

kesy * 查询所有key
scan * 查询特定的key

### 原理








 

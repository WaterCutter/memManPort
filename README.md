# 如何剪裁操作系统源码
本文面向的需求场景是，为缺乏标准库实现的处理器IP移植内存管理模块，即为裸片部署C标准库中的 `malloc()` 和 `free()` 函数。

具体做法是——从操作系统的内存管理组件中剪裁出必要的源码，适配到目标处理器的开发环境（SDK/IDE/CMAKE工程子目录）中。

## 1 定需求——理解内存管理/堆管理
### 1.1 C标准库中的内存管理方案 


C标准库提供了一组内存管理函数，用于在C程序中进行动态内存分配和释放操作。这些函数主要包括malloc、calloc、realloc和free。

malloc函数: malloc函数用于分配指定大小的内存块，并返回指向该内存块的指针。其函数原型为：

    
```c
void* malloc(size_t size);
```
    
它接受一个参数size，表示需要分配的内存空间的大小（以字节为单位）。malloc函数在堆内存中分配了一块连续的内存，并返回指向该内存块起始地址的指针。

calloc函数: calloc函数也用于分配指定数量和大小的内存块，并返回指向该内存块的指针。与malloc不同的是，calloc会将分配的内存块中的每个字节都初始化为0。其函数原型为：

```c
void* calloc(size_t num, size_t size);
```
    
num参数表示需要分配的元素个数，而size参数表示每个元素的大小（以字节为单位）。calloc函数在堆内存中分配了大小为num * size的内存块，并返回指向该内存块起始地址的指针。

realloc函数: realloc函数用于调整先前分配的内存块的大小。其函数原型为：

    
```c
void* realloc(void* ptr, size_t size);
```
    
ptr参数是指向先前通过malloc或calloc分配的内存块的指针，而size参数表示需要调整的大小（以字节为单位）。realloc函数根据新的大小重新分配内存块，并返回指向重新分配后内存块起始地址的指针。如果内存块不能被重新分配，realloc函数可能会创建新的内存块，并将原内存块的数据复制到新内存块中。

free函数: free函数用于释放先前通过malloc、calloc或realloc函数分配的内存块。其函数原型为：

    
```c
void free(void* ptr);
```
 
ptr参数是指向先前分配的内存块的指针。通过调用free函数，该内存块将被标记为空闲，并可以被再次分配给其他内存需求。

### 1.2 需求剪裁
裸片程序受限于内存资源，一般是使用静态分配方法设计得到的，只在移植某些外设的驱动时需要提供基本的动态内存管理方法，很少有新增预分配的动态内存的需求。所以 `realloc` 和 `calloc` 函数可以略去，这样咱的任务量就减少了一半啦。

## 2 找轮子——向操作系统学习
操作系统是对硬件的抽象，裸片上的绝大部分需求都可以在操作系统的源码中找到较为通用的实现，那么何必再造轮子呢，直接逮着操作系统的薅羊毛吧。
### 2.1 FreeRTOS中的内存管理方案
FreeRTOS 提供了几种堆管理方案，这些方案的复杂性和功能各不相同，分别适用于不同的需求场景，具体见下图。
![在这里插入图片描述](https://img-blog.csdnimg.cn/d3ce60e0812441fc91ab90359f7f2159.png#pic_center)
总结性地说，FreeRTOS在源码目录 Source/Portable/MemMang 中为咱们提供了 5 种可选的内存管理模块的实现：
- heap_1：极简版，不支持内存释放（没有 free 函数）
- heap_2：支持释放，但不合并释放的内存块
- heap_3：支持线程安全的 malloc 和 free 函数
- heap_4：合并释放的内存块，避免内存碎片
- heap_5：在 4 的基础上支持跨多个内存块进行分配

这儿咱们根据自己的需求选，本文选择 heap_2 移植，因为基本功能全面，且足够简单。

### 2.2 拉取源码
在源码树中找到 Source/Portable/MemMang/heap2.c，如下图。
![在这里插入图片描述](https://img-blog.csdnimg.cn/008fec67ea0746f993815125e2a8a603.png#pic_center)
打开就看到分配和释放函数触手可及，分别命名为 `pvPortMalloc` 和 `vPortFree`, 添加到咱的工程里，然后细看这个源文件的依赖，把依赖项从源码树里抠出来，舍弃不需要的文件，也就把内存管理模块从操作系统中剥离出来了。
### 2.3 剥离依赖项
heap_2.c包含了两个FreeRTOS相关的头文件—— FreeRTOS.h 和 task.h，后者是任务调度器相关的声明，咱们显然不需要，直接剔除。FreeRTOS是一些配置项的宏定义，咱们把与内存管理相关的剪切过来，不需要保留FreeRTOS.h整个文件。

![在这里插入图片描述](https://img-blog.csdnimg.cn/64aef9717388490d9281dc2daac9ee6c.png#pic_center)

然后是一个用于让管理的内存空间大小符合内存对齐需求的宏定义：
```c
/* A few bytes might be lost to byte aligning the heap start address. */
#define configADJUSTED_HEAP_SIZE    ( configTOTAL_HEAP_SIZE - portBYTE_ALIGNMENT )
```
configTOTAL_HEAP_SIZE 和 portBYTE_ALIGNMENT 都需要我们手动 #define
![在这里插入图片描述](https://img-blog.csdnimg.cn/ebf242054d4f405096a892c152535b04.png#pic_center)
heap_2.c 还用到一个宏定义 `portBYTE_ALIGNMENT_MASK`：
![在这里插入图片描述](https://img-blog.csdnimg.cn/c9e0b5cb0e2045f7a5d17545cdde1c18.png#pic_center)
原先在FreeRTOS.h里，我们加到portmacro.h里：
![在这里插入图片描述](https://img-blog.csdnimg.cn/47271df8576c423193e82d0c50aed227.png#pic_center)
剩下的就是一些基本的类型替换了，我们统一放到 portmacro.h 文件中：
![在这里插入图片描述](https://img-blog.csdnimg.cn/ecb2ab00ed9d4ce6953f67bb4e2b572d.png#pic_center)
projdefs.h 也是需要的，里面有 `true` 和 `false` 的宏：
![在这里插入图片描述](https://img-blog.csdnimg.cn/347d2fe2c02b4e4f821845ab6dd556b7.png#pic_center)
### 2.4 可用源码

## 3 测试
可以用下面这个demo来测试移植结果的可用性，只要pb和pc值结果一致，那就基本正确了。
![在这里插入图片描述](https://img-blog.csdnimg.cn/9f2c5fc72d704f5fa6c2e2709dc22008.png)

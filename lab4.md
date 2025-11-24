# Lab4 实验报告

### 练习1：分配并初始化一个进程控制块

> alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
> 
> - 请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

**解答：**

- `alloc_proc`函数的实现分为以下四个方面：
  
  - ​**内存分配**​：使用 `kmalloc` 为新的进程控制块 `proc_struct` 分配内存空间
    
  - **空指针检查**​：检查内存分配是否成功，如果失败则返回 NULL
    
  - ​**字段初始化**​：对 `proc_struct` 的所有成员变量进行初始化：
    
    - 进程状态设为未初始化（`PROC_UNINIT`）
    - PID 设为 -1（无效值）
    - 运行次数、内核栈、调度标志等设为 0 或 NULL
    - 使用 `memset` 清空上下文和进程名称
  - ​**返回指针**​：返回初始化后的进程控制块指针
    
- 具体实现如下：
  
- ```bash
  alloc_proc(void)
  {
      struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
      if (proc != NULL)
      {
          proc->state = PROC_UNINIT;
          proc->pid = -1;
          proc->runs = 0;
          proc->kstack = 0;
          proc->need_resched = 0;
          proc->parent = NULL;
          proc->mm = NULL;
          memset(&(proc->context), 0, sizeof(struct context));
          proc->tf = NULL;
          proc->pgdir = boot_pgdir_pa;
          proc->flags = 0;
          memset(proc->name, 0, PROC_NAME_LEN + 1);
      }
      return proc;
  }
  ```
  
- `struct context context`的含义和作用：
  
  - 进程的上下文信息，保存进程执行时的寄存器状态
    
  - 在进程切换时保存当前进程的寄存器状态
    
  - 当切换回该进程时，从 context 恢复寄存器状态，实现进程的继续执行
    
  - 该成员是实现进程调度和上下文切换的核心数据结构
    
- `struct trapframe *tf`的含义和作用：
  
  - 陷阱帧指针，保存中断/异常发生时的完整处理器状态
    
  - 当中断或异常发生时，自动保存处理器的全部状态信息
    
  - 用于内核态和用户态之间的切换，保存用户进程的执行现场
    
  - 在系统调用、中断处理等场景中，通过 tf 可以获取和修改进程的执行状态
    
  - 对于新创建的进程，tf 可以设置其初始执行环境
    

### 练习2：为新创建的内核线程分配资源

> 创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用do_fork函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：
> 
> - 调用alloc_proc，首先获得一块用户信息块。
> - 为进程分配一个内核栈。
> - 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
> - 复制原进程上下文到新进程
> - 将新进程添加到进程列表
> - 唤醒新进程
> - 返回新进程号
> 
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
> 
> - 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

**解答 :**

1. **实现过程**
  
  - 检查进程数量限制
  
  ```c++
  int ret = -E_NO_FREE_PROC;
  struct proc_struct *proc;
  if (nr_process >= MAX_PROCESS) {
      goto fork_out;
  }
  ret = -E_NO_MEM;
  ```
  
  检查当前系统进程数是否已达上限 `MAX_PROCESS`。如果达到上限，跳转到 `fork_out` 返回错误码 `-E_NO_FREE_PROC`；否则，预设错误码为 `-E_NO_MEM`（后续步骤可能因内存不足失败）
  
  - 分配进程控制块
  
  ```c++
  if ((proc = alloc_proc()) == NULL) {
      goto fork_out;
  }
  proc->parent = current;
  ```
  
  调用`alloc_proc`，分配一个 `proc_struct` 结构体，初始化所有字段为默认值，并设置了父进程。如果内存分配失败，直接返回错误。
  
  - 分配内核栈
  
  ```c++
  if (setup_kstack(proc) != 0) {
      goto bad_fork_cleanup_proc;
  }
  ```
  
  为新进程分配 `KSTACKPAGE` 个物理页作为内核栈，用于保存进程在内核态执行时的局部变量、中断/异常时的 trapframe 以及上下文切换时的 context。如果分配失败，跳转到 `bad_fork_cleanup_proc`，释放已分配的 PCB，然后返回错误。
  
  - 共享内存管理信息
  
  ```c++
  if (copy_mm(clone_flags, proc) != 0) {
      goto bad_fork_cleanup_kstack;
  }
  ```
  
  `copy_mm` 会根据 `clone_flags` 决定是复制还是共享父进程的内存管理结构 `mm`：如果 `clone_flags | CLONE_VM`，那么共享内存，创建线程；否则复制内存，创建进程。本次实验中，当前所有进程都是内核线程，`mm == NULL`，所以 `copy_mm` 为空，直接返回 0。但如果没有返回0，则跳转到 `bad_fork_cleanup_kstack`，释放内核栈和 PCB，然后返回错误。
  
  - 设置 trapframe 和 context
  
  ```c++
  copy_thread(proc, stack, tf);
  ```
  
  调用 `copy_thread` 函数，复制了父进程的 trapframe，把子进程的返回值设置为 0，并设置子进程的栈指针（指向 trapframe ）以及 context 的返回地址( forkret )和栈指针（ trapframe ）。
  
  - 加入进程管理结构（临界区）
  
  ```c++
  bool intr_flag;
  local_intr_save(intr_flag);
  {
      proc->pid = get_pid();              // 分配唯一 PID
      hash_proc(proc);                    // 加入 hash 表
      list_add(&proc_list, &(proc->list_link)); // 加入进程链表
      nr_process++;                       // 进程数加 1
  }
  local_intr_restore(intr_flag);
  ```
  
  这一步要关闭中断，因为这些操作修改全局共享数据结构。
  
  - 唤醒新进程
  
  ```c++
  wakeup_proc(proc);
  ```
  
  将进程状态从 `PROC_UNINIT` 改为 `PROC_RUNNABLE`，此时进程已经准备好被调度执行。
  
  - 返回子进程 PID
  
  ```c++
  ret = proc->pid;
  ```
  
  成功创建子进程后，返回子进程的 PID，父进程通过这个返回值知道子进程的 PID。
  
2. 问题解答：ucore是否做到给每个新fork的线程一个唯一的id？
  

是的，uCore 通过 `get_pid()` 函数保证了每个新创建的进程/线程都有唯一的 PID：

`get_pid` 中，首先初始化了一些变量：

```c++
 static_assert(MAX_PID > MAX_PROCESS); // 确保PID 空间 > 进程数上限
 struct proc_struct *proc; // 临时指针，用于遍历进程
 list_entry_t *list = &proc_list, *le; // 进程链表头，链表遍历指针
 static int next_safe = MAX_PID, last_pid = MAX_PID; // next_safe: 下一个安全PID， last_pid: 上一个分配的PID
```

以下代码是保证 pid 分配唯一性的关键代码：

```c++
   // 快速路径：尝试递增  
   if (++last_pid >= MAX_PID)
    {
        last_pid = 1; // 回绕到 1
        goto inside;  // 跳转到检查逻辑
    }
   //  需要更新 next_safe
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) // 遍历所有进程
        {
            proc = le2proc(le, list_link);
            // 存在冲突，自增
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            // 重新设置 next_safe：大于且离 last_pid 最近的一个proc_pid
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;
            }
        }
    }
```

从整体上看，其实就是从 last_pid + 1 开始查找，若冲突则继续 +1，直到找到一个未被占用的 PID。该算法的巧妙在于 next_safe 的设计，它记录"下一个已被占用的 PID"，如果 `last_pid < next_safe`，说明中间没有冲突，直接返回，这样可以减少不必要的遍历。

### 练习3：编写proc_run 函数

> proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：
> 
> - 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
> - 禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。
> - 切换当前进程为要运行的进程。
> - 切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lsatp(unsigned int pgdir)函数，可实现修改SATP寄存器值的功能。
> - 实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。
> - 允许中断。

**实现过程 :** 实现代码如下：

```c++
void proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        bool intr_flag;
        local_intr_save(intr_flag); // 关中断
        if (proc == current) {
            local_intr_restore(intr_flag);
            return;
        } // 防止在关中断前current再次切换
        struct proc_struct *old=current;
        current=proc; // 切换进程
        proc->runs++; // 更新进程相关状态
        current->need_resched = 0; // 不需要调度
        lsatp(proc->pgdir); // 切换页表
        switch_to(&old->context,&proc->context); // 上下文切换
        local_intr_restore(intr_flag); // 开中断
    }
}
```

首先关闭中断，然后再次检查是否需要切换进程防止在关闭中断时又发生了进程切换。然后切换进程，更新新进程的计数，把是否需要调度设置成不需要，然后切换页表、上下文切换，最后打开中断。

> 请回答如下问题：
> 
> - 在本实验的执行过程中，创建且运行了几个内核线程？

**解答 :** 内核初始化的时候会调用 proc_init，proc_init 中先分配并运行 idleproc，然后通过 kernel_thread 创建并运行 initproc，因此本实验创建并运行了 idleproc 和 initproc 两个内核线程。

### 扩展练习 Challenge

1. **说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？**

**解答 :**

- `local_intr_save(intr_flag)`读取当前 CPU 的中断使能状态,然后立即禁止中断，将之前的中断状态保存至`intr_flag` 中。
  
- `local_intr_restore(intr_flag)`会读取原来的中断状态并将其恢复。
  

2. **深入理解不同分页模式的工作原理**

> get_pte()函数（位于kern/mm/pmm.c）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
> 
> - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
> - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

**解答 :**

1. 两段代码为什么如此相像
  
  那两段相似代码实在遍历同一个多级页表的不同层次。
  
  页表遍历的本质是在每一层都执行相同的操作：首先，根据当前处理的虚拟地址部分（VPN）提取出本层的页表索引；然后，用这个索引在当前页表中找到对应的页表项（PTE）；接着，检查这个PTE。如果PTE无效但允许创建，就需要分配一个新的物理页作为下一级页表，并更新当前PTE使其指向这个新页。最后，进入下一级页表继续这个过程。这个模式在每一层都是完全一样的，因此在代码实现上就表现为高度相似的段落。
  
  sv32、sv39 和 sv48 这三种模式决定了整个页表的结构。sv32用于32位虚拟地址，采用2级页表，每级索引10位；sv39用于39位虚拟地址，采用3级页表，每级索引9位；sv48用于48位虚拟地址，采用4级页表，每级索引9位。这三种模式的差异只影响了遍历的循环次数（或代码展开的层数）以及在每层提取索引时所用的位移和掩码等参数，并没有改变每一层需要执行的核心操作流程。
  
  本操作系统使用的是sv39模式，有三级页表，最顶层页表直接索引并检查，后两级页表需要遍历，所以get_pte()中会有两段相似代码。
  
2. 这种写法好吗？有没有必要把两个功能拆开？
  
  优点：
  
  - 使用方便，调用者只需调用一个函数即可完成“查找或按需创建”的需求。
  - 能在一个原子操作上下文里完成查找和创建，方便使用开关中断操作或锁来保护整个过程，确保操作的原子性。
  
  缺点：
  
  - 函数既负责“查找”又负责“写入分配”，既有读又有写，增加了理解和维护函数的难度。
  - 容易被误用，比如给不该分配内存的中断处理的特定阶段错误地分配了内存。
  - 函数出错的时候不方便调试，比如create = false时返回NULL意味着PTE不存在，而create = true时返回NULL则意味着内存分配失败。
  
  有必要把两个功能分开，两个函数各司其职，方便调试，且可读性更好。可以分成两个函数，一个函数只负责查找，一个函数负责查找和写入分配，这样既减少了误分配内存的概率，又保留了查找和按需创建操作的原子性。
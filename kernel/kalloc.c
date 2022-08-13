// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
  char lock_name[7];
} kmem[NCPU];
 
void
kinit()
{
  for (int i = 0; i < NCPU; i++) {
    snprintf(kmem[i].lock_name, sizeof(kmem[i].lock_name), "kmem_%d", i);
    initlock(&kmem[i].lock, kmem[i].lock_name);
  }
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  push_off();
  int id = cpuid();

  acquire(&kmem[id].lock);
  r->next = kmem[id].freelist;
  kmem[id].freelist = r;
  release(&kmem[id].lock);

  pop_off();
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  push_off();
  int id = cpuid();

  acquire(&kmem[id].lock);
  r = kmem[id].freelist;
  if(r)
    kmem[id].freelist = r->next;
  else{
    // 如果当前cpu没有空闲页面，则到其他cpu上申请页面
    int flag = 0;//success or fail
    int i = 0;
    for(i = 0; i < NCPU; i++) {
      if (i == id) continue;

      acquire(&kmem[i].lock);
      struct run *p = kmem[i].freelist;
      if(p) {
        // steal half of memory
        //fp每次移动两个步长，p移动一个步长，pre是p的前指针
        struct run *fp = p; // faster pointer
        struct run *pre = p;
        while (fp && fp->next) {
          fp = fp->next->next;
          pre = p;
          p = p->next;
        }//fp到链表尾端，p指向链表中段

        kmem[id].freelist = kmem[i].freelist;//本cpu获取前半段页面
        if (p == kmem[i].freelist) {
          // only have one page
          kmem[i].freelist = 0;
        }
        else {
          kmem[i].freelist = p;
          pre->next = 0;
        }
        flag = 1;
      }
      release(&kmem[i].lock);

      if (flag) {
        r = kmem[id].freelist;
        kmem[id].freelist = r->next;
        break;
      }
    }
  }

  release(&kmem[id].lock);
  pop_off();

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
---
layout: default
title: "Design a Multiple Producer Multiple Consumer (MPMC) thread-safe queue in C++"
seo_h1: "How would you design an MPMC thread-safe queue in C++?"
date: 2026-01-27 00:00:01 +0530
categories: cpp
tags: [cpp-core, concurrency, multithreading, thread-safety, data-structures]
mathjax: false
description: Comprehensive guide to designing a thread-safe queue with multiple implementation approaches
published: true
hidden: false
---

## Overview

### 1. What is Thread Safety?

**Thread safety** is a property of a piece of code that guarantees it will behave correctly—maintaining **internal invariants** (e.g., ensuring that a 'size' counter always reflects the actual number of nodes in a list, rather than becoming desynchronized during simultaneous updates) and **data integrity** (e.g., preventing a consumer from reading a half-constructed object or ensuring bits aren't flipped during a concurrent write)—when executed by multiple threads simultaneously.

<!-- <img src="/assets/images/thread-safe-queue-producer-flow.png" alt="Producer Flow in Thread-Safe Queue" style="display: block; margin: 0 auto; width: 60%;" /> -->

An MPMC (Multiple Producer Multiple Consumer) thread-safe queue is a concurrent data structure that allows multiple producer threads to enqueue elements and multiple consumer threads to dequeue elements simultaneously without data races or corruption. The key challenges include:

- **Mutual Exclusion**: All shared state transitions (container + control flags) are serialized under a mutex to preserve invariants. Use a `std::mutex` to protect push/pop operations—keep the locked section short (just the queue modification), and for better performance, use separate locks for the front and back of the queue so one thread can push while another pops. Always use RAII (`std::lock_guard`, `std::unique_lock`) so the lock releases automatically even if something throws an exception.
- **Synchronization**: When the queue is empty, consumer threads shouldn't spin-wait. Instead, they sleep on a `std::condition_variable` and wait on the predicate `!q.empty() || closed` to guarantee progress and handle spurious wakeups. After a producer pushes an item and releases the lock, it calls `notify_one()` to wake a waiting consumer (or `notify_all()` when shutting down the queue).
- **Performance**: Multiple threads fighting for the same lock creates a bottleneck. Minimize time inside the critical section by preparing data outside the lock, or split your queue into multiple independent queues (sharding) or use separate head/tail locks. If profiling shows serious contention, consider lock-free implementations with atomics and compare-and-swap, but watch for false sharing (use cache-line alignment/padding).
- **Safety**: Avoid the "Four Horsemen"—deadlocks (threads waiting on each other forever), race conditions (unpredictable results from timing), livelocks (threads endlessly reacting to each other), and undefined behavior. Always acquire locks in the same order, never hold a lock while calling user callbacks, use RAII so exceptions can't leave locks held, notify outside the lock, use predicate-based waits to handle spurious wakeups, and provide a shutdown mechanism so blocked threads can exit cleanly.

## Design Considerations

### Step 1 — Define the problem and the boundary of responsibility

We want a queue that can be accessed by multiple threads concurrently without corrupting its internal state or exposing partially-updated data to readers. The queue's responsibility is narrowly scoped: 
* it must provide safe concurrent `push` and `pop` operations, and    
* it must define what happens when consumers have no work (empty queue) and when the system is shutting down.   

Everything else—task semantics, work distribution strategy, backpressure policy, and producer lifecycle—belongs to the application layer, not the queue.

In other words: the queue is a synchronization boundary. If a bug happens outside (e.g., producers never signal shutdown), the queue should still behave predictably and avoid deadlocks *as long as the caller uses the defined API*.

<img src="/assets/images/queue-synchronization-boundary.png" alt="Queue Synchronization Boundary" style="display: block; margin: 0 auto; width: 40%;" />

### Step 2 — State the concurrency model explicitly

The queue design begins by stating who can call what, concurrently. The baseline expectation is **MPMC** (multi-producer, multi-consumer): many threads may call `push()` at the same time, and many threads may call `pop()` at the same time.

This matters because it determines the minimal synchronization requirements. An SPSC queue can be lock-free with simple atomics; MPMC generally requires either more complex lock-free algorithms or a lock-based critical section. Since this is the "basic mutex-based" implementation, we are intentionally choosing mutual exclusion to simplify correctness, while still being production-usable.

### Step 3 — Define the API contract in terms of behaviors, not just functions

Before code, we declare what operations mean and what they guarantee.

* A `push(T)` must atomically make a new item visible to consumers. "Atomically" here means consumers will never observe a half-constructed node or an inconsistent container state. The `push` should also trigger progress: if a consumer is blocked waiting for work, `push` should wake one of them so the system doesn't stall.

* A blocking pop (often named `wait_pop`, `pop_blocking`, etc.) must be a *sleeping wait*, not a spin loop. If the queue is empty, the consumer thread parks on a condition variable and wakes only when the predicate indicates it can make progress. A non-blocking `try_pop` is useful for polling loops and shutdown checks, but it should have a crisp contract: it returns immediately and succeeds only if an item is available at that instant.

The key is that the **queue defines progress and visibility guarantees, while the application decides how many threads exist** and what "work" means.

### Step 4 — Establish the internal invariants (the "must never be broken" rules)

To build a thread-safe data structure, you define invariants that must hold after every public operation, even when exceptions occur.

For a basic queue, the core invariants are designed to prevent specific concurrency hazards:

1. The underlying container's structure is consistent   
Without synchronization, two threads performing a push can simultaneously update the "tail" pointer, causing one node to be overwritten and lost (a memory leak) or leaving a pointer referencing uninitialized memory. This creates a broken chain where a consumer thread follows a garbage address, leading to a segmentation fault or a "half-baked" state where a node is visible to readers before its data members are actually constructed.

2. Size-related observations (if exposed) match the container reality   
If the size counter is updated independently of the data insertion, a race condition can cause the count to drift from the actual number of elements. For example, a consumer might see size > 0 and attempt a pop, but because the producer was interrupted before finishing the actual data link, the consumer attempts to read a null object, or conversely, a consumer might deadlock by waiting on a queue that actually contains items the counter failed to acknowledge.

3. The shutdown/closed flag is consistent with the lifecycle state   
If the `closed` flag is not tightly coupled with the synchronization primitives, a race condition (the "lost wakeup") can leave threads stranded during shutdown. A consumer might read the flag as "open" and proceed to wait; however, if the shutdown signal arrives in the narrow window between the check and the wait, the consumer misses the notification and hangs indefinitely, preventing the application from exiting cleanly.   

Most importantly, there must be **no data races**: *every read/write of shared state that can be concurrently accessed must be synchronized*.

From a correctness and efficiency standpoint, "thread-safe" is not just "put a mutex everywhere"—it means there is a coherent rule: *any access to shared state must happen while holding the mutex, and any waiting must re-check the predicate while holding the same mutex.* Adhering to this rule ensures your design satisfies two critical requirements:

* **Robustness:** This rule eliminates the **Time-of-Check to Time-of-Use (TOCTOU)** race condition by ensuring that the "reality" of the queue cannot change between the moment a thread checks a condition and the moment it executes the operation; it guarantees that internal invariants remain stable and that no thread ever acts on stale or "half-baked" information.
* **Performance:** This pattern is the only way to safely implement **sleeping waits** via condition variables, which allows consumer threads to remain suspended and consume zero CPU cycles until the exact moment work is available; this prevents the system from wasting power and processing time on "busy-waiting" loops that would otherwise throttle high-performance pipelines.

### Step 5 — Choose the synchronization primitives and explain why

For the basic design we use:

- `std::mutex` to protect the queue and its control flags.
- `std::condition_variable` to avoid busy waiting when the queue is empty.

This pairing is standard practice because the mutex provides mutual exclusion (one writer at a time to the container), while the condition variable provides efficient waiting and waking without burning CPU cycles.

A condition variable is not "a notification channel" by itself. **The condition variable is only a sleep/wake mechanism; correctness comes from the predicate guarded by the mutex.** That's why every wait must be done as `cv.wait(lock, predicate)` or an equivalent loop.

### Step 6 — Define the wait predicate (this is the heart of the design)

The blocking `pop` must wait on a predicate that represents "it is safe and meaningful to proceed." For a queue, that predicate is typically:

- proceed if there is data: `!queue.empty()`
- or proceed if shutdown is requested: `closed == true`

So the predicate is: `!queue.empty() || closed`.

This addresses two separate realities: normal operation (items arriving) and lifecycle termination (threads must be able to exit cleanly). It also cleanly handles spurious wakeups because the predicate is re-evaluated under the lock every time the thread wakes.

### Step 7 — Specify shutdown semantics precisely (avoid "done means ???")

Most real concurrency bugs come from vague shutdown behavior. So we define it precisely:

We provide `close()` / `shutdown()` that sets a `closed` flag under the mutex and then wakes all waiting consumers via `notify_all()`. After closing, `push()` is either disallowed (return false / throw / ignore) depending on your policy, but it must be consistent.

For consumers: if they wake and see `queue.empty() && closed`, they return "no more work" immediately (commonly `false` or empty `std::optional`). This ensures no thread blocks forever when producers are finished.

The important architect-level point: shutdown is not the same as "queue is empty." Empty is a transient state; shutdown is a terminal state.

### Step 8 — Decide notification strategy: `notify_one` vs `notify_all`

In normal operation, `push()` should typically call `notify_one()` because one new item usually enables progress for one consumer. This avoids waking multiple threads only to have them contend for the same mutex and find no additional work—classic thundering herd.

`notify_all()` is reserved for state transitions that affect *all waiters*, most notably shutdown. When the queue closes, every waiting consumer must be released so each can observe `closed == true` and exit. That is why shutdown uses `notify_all()` even if no items are added.

Also: you can notify either before or after releasing the lock; the usual recommendation is **modify shared state under lock → release lock → notify** to reduce unnecessary contention, while still relying on the predicate for correctness.

### Step 9 — Keep the critical section small (performance posture)

Even in the "basic" version, we design with performance posture in mind. The mutex-protected section should only cover the minimal work needed to maintain invariants: pushing into the container, popping from it, and touching shared flags.

Anything expensive—allocations, conversions, heavy object construction—should ideally be done outside the lock when possible (subject to your API shape). This keeps contention low and improves throughput under multi-threaded load.

The key bottleneck to recognize: as concurrency increases, mutex contention becomes the limiter. The basic queue is correct and acceptable for many systems, but it has a known scaling profile.

### Step 10 — Exception safety and "no invariant left behind"

A correct queue must remain valid even if element move/copy constructors throw. The design must ensure that operations either complete fully or leave the queue unchanged (strong guarantee) or at least leave it in a valid state (basic guarantee).

Using RAII locks (`std::lock_guard`, `std::unique_lock`) ensures the mutex is always released, even when exceptions occur. Then the remaining requirement is: container modifications must not leave structural corruption. Standard containers maintain their own invariants; our job is to ensure we don't expose partial state across threads.

### Step 11 — Clarify what this basic design is intentionally not doing

To keep correctness transparent, the basic design does not attempt lock-free progress, sharding, work stealing, bounded backpressure, fairness guarantees, or priority scheduling. Those are higher-level or specialized requirements.

This statement is important because it prevents over-claiming. Clear documentation of what a design guarantees—and what it does not—builds trust and sets proper expectations.

### Step 12 — Summarize the contract in one sentence

This basic mutex-based queue provides **MPMC-safe push/pop**, **blocking pop via condition-variable predicate**, and a **defined shutdown path** so consumers can exit cleanly without spinning or deadlocking.

---

## Basic Implementation (Mutex-Based)

The simplest approach uses a mutex to protect all operations:

```cpp
#include <condition_variable>
#include <cstddef>
#include <memory>
#include <mutex>
#include <optional>
#include <utility>
#include <atomic>

template <typename T>
class ThreadSafeQueue {
private:
    struct Node {
        std::shared_ptr<T> data;
        std::unique_ptr<Node> next;
    };

    // Two-lock queue internals (performance + reduced contention)
    mutable std::mutex head_mtx_;
    mutable std::mutex tail_mtx_;
    std::condition_variable data_cv_;

    std::unique_ptr<Node> head_;
    Node* tail_;

    // Safety: close-aware behavior
    std::atomic<bool> closed_{false};

    // Performance/utility: O(1) size
    std::atomic<std::size_t> size_{0};

    // Head-side helpers
    std::unique_lock<std::mutex> wait_for_data() {
        std::unique_lock<std::mutex> head_lock(head_mtx_);
        data_cv_.wait(head_lock, [this] {
            // Predicate-based wait handles spurious wakeups.
            // Wake when:
            // 1) there is data, OR
            // 2) queue is closed (so consumers can exit cleanly)
            return closed_.load(std::memory_order_acquire) || head_.get() != get_tail();
        });
        return head_lock;
    }

    Node* get_tail() const {
        std::lock_guard<std::mutex> tail_lock(tail_mtx_);
        return tail_;
    }

    std::unique_ptr<Node> pop_head() {
        // head_mtx_ must already be held
        auto old_head = std::move(head_);
        head_ = std::move(old_head->next);
        return old_head;
    }

    std::shared_ptr<T> try_pop_shared() {
        std::lock_guard<std::mutex> head_lock(head_mtx_);

        if (head_.get() == get_tail()) {
            return {};
        }

        auto old_head = pop_head();
        size_.fetch_sub(1, std::memory_order_release);
        return std::move(old_head->data);
    }

    std::shared_ptr<T> wait_pop_shared() {
        auto head_lock = wait_for_data();

        // If closed and empty -> exit cleanly
        if (head_.get() == get_tail()) {
            return {};
        }

        auto old_head = pop_head();
        size_.fetch_sub(1, std::memory_order_release);
        return std::move(old_head->data);
    }

public:
    ThreadSafeQueue() : head_(std::make_unique<Node>()), tail_(head_.get()) {}

    ThreadSafeQueue(const ThreadSafeQueue&) = delete;
    ThreadSafeQueue& operator=(const ThreadSafeQueue&) = delete;

    // ---- Producer API ----

    // Push by value (supports move)
    bool push(T value) {
        return emplace(std::move(value));
    }

    // Perfect-forwarding emplace
    template <typename... Args>
    bool emplace(Args&&... args) {
        // Allocate/construct OUTSIDE the lock to keep critical section short
        auto new_data = std::make_shared<T>(std::forward<Args>(args)...);
        auto new_node = std::make_unique<Node>();
        Node* new_tail_ptr = new_node.get();

        {
            std::lock_guard<std::mutex> tail_lock(tail_mtx_);

            // If closed, reject new items (safety: no silent enqueues after shutdown)
            if (closed_.load(std::memory_order_acquire)) {
                return false;
            }

            tail_->data = std::move(new_data);
            tail_->next = std::move(new_node);
            tail_ = new_tail_ptr;

            size_.fetch_add(1, std::memory_order_release);
        }

        // Notify AFTER releasing the lock (avoids waking a thread just to block again)
        data_cv_.notify_one();
        return true;
    }

    // ---- Consumer API ----

    // Non-blocking: returns empty optional if no item available
    std::optional<T> try_pop() {
        auto data = try_pop_shared();
        if (!data) return std::nullopt;
        return std::move(*data);
    }

    // Blocking: waits for data or close(); returns false if closed AND empty
    bool wait_pop(T& out) {
        auto data = wait_pop_shared();
        if (!data) return false; // closed + empty
        out = std::move(*data);
        return true;
    }

    // Blocking convenience: returns optional
    std::optional<T> wait_pop() {
        auto data = wait_pop_shared();
        if (!data) return std::nullopt;
        return std::move(*data);
    }

    // ---- Lifecycle / Safety ----

    // Closes the queue:
    // - further pushes are rejected
    // - all waiters wake up
    void close() {
        closed_.store(true, std::memory_order_release);
        data_cv_.notify_all();
    }

    bool closed() const noexcept {
        return closed_.load(std::memory_order_acquire);
    }

    // Approx. O(1) size (atomic). Exact for this implementation’s push/pop paths.
    std::size_t size() const noexcept {
        return size_.load(std::memory_order_acquire);
    }

    bool empty() const noexcept {
        return size() == 0;
    }
};

```

## Key Design Decisions

### 1. Synchronization Strategy

**Condition Variables**:
- Use `std::condition_variable` to block consumers when queue is empty
- `notify_one()` after each push to wake waiting threads
- More efficient than busy-waiting or polling

**Lock Granularity**:
- Fine-grained: Separate locks for head and tail (more complex)
- Coarse-grained: Single lock for entire queue (simpler, but higher contention)

### 2. Exception Safety

```cpp
void push(T value) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(value));  // May throw
    }  // Lock released even if exception
    cv_.notify_one();  // Outside lock to avoid holding during notification
}
```

**Important considerations**:
- Always notify outside the lock to prevent unnecessary blocking
- Use RAII locks (`lock_guard`, `unique_lock`) for exception safety
- Move semantics to avoid unnecessary copies

### 3. Bounded vs Unbounded Queue

**Unbounded** (shown above):
- Can grow indefinitely
- Simpler implementation
- Risk of memory exhaustion

**Bounded** (fixed capacity):
```cpp
template<typename T>
class BoundedThreadSafeQueue {
private:
    std::queue<T> queue_;
    size_t capacity_;
    mutable std::mutex mutex_;
    std::condition_variable cv_not_full_;
    std::condition_variable cv_not_empty_;
    
public:
    explicit BoundedThreadSafeQueue(size_t capacity) 
        : capacity_(capacity) {}
    
    void push(T value) {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_not_full_.wait(lock, [this] { 
            return queue_.size() < capacity_; 
        });
        queue_.push(std::move(value));
        lock.unlock();
        cv_not_empty_.notify_one();
    }
    
    T pop() {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_not_empty_.wait(lock, [this] { 
            return !queue_.empty(); 
        });
        T value = std::move(queue_.front());
        queue_.pop();
        lock.unlock();
        cv_not_full_.notify_one();
        return value;
    }
};
```

### 4. Shutdown/Termination Support

For graceful shutdown, add a done flag:

```cpp
template<typename T>
class ThreadSafeQueue {
private:
    std::queue<T> queue_;
    mutable std::mutex mutex_;
    std::condition_variable cv_;
    bool done_ = false;
    
public:
    void shutdown() {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            done_ = true;
        }
        cv_.notify_all();
    }
    
    std::optional<T> pop() {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_.wait(lock, [this] { 
            return !queue_.empty() || done_; 
        });
        
        if (queue_.empty()) {
            return std::nullopt;  // Shutdown occurred
        }
        
        T value = std::move(queue_.front());
        queue_.pop();
        return value;
    }
};
```

## Advanced: Lock-Free Implementation

For maximum performance in high-contention scenarios:

```cpp
#include <atomic>
#include <memory>

template<typename T>
class LockFreeQueue {
private:
    struct Node {
        std::shared_ptr<T> data;
        std::atomic<Node*> next;
        
        Node() : next(nullptr) {}
    };
    
    std::atomic<Node*> head_;
    std::atomic<Node*> tail_;
    
public:
    LockFreeQueue() {
        Node* dummy = new Node();
        head_.store(dummy);
        tail_.store(dummy);
    }
    
    ~LockFreeQueue() {
        while (Node* old_head = head_.load()) {
            head_.store(old_head->next);
            delete old_head;
        }
    }
    
    void push(T value) {
        auto data = std::make_shared<T>(std::move(value));
        Node* new_node = new Node();
        Node* old_tail = tail_.load();
        
        while (true) {
            old_tail->data = data;
            Node* null_ptr = nullptr;
            if (old_tail->next.compare_exchange_strong(null_ptr, new_node)) {
                tail_.compare_exchange_weak(old_tail, new_node);
                return;
            }
            old_tail = tail_.load();
        }
    }
    
    std::shared_ptr<T> try_pop() {
        Node* old_head = head_.load();
        while (old_head != tail_.load()) {
            if (head_.compare_exchange_weak(old_head, old_head->next)) {
                std::shared_ptr<T> result = old_head->next->data;
                delete old_head;
                return result;
            }
        }
        return nullptr;
    }
};
```

**Challenges with lock-free**:
- Complex to implement correctly
- ABA problem requires careful handling
- Memory reclamation is difficult (use hazard pointers or epoch-based reclamation)
- Debugging is extremely challenging

## Performance Considerations

### 1. Lock Contention Reduction

**Strategy 1**: Multiple queues (sharding)
```cpp
template<typename T>
class ShardedQueue {
private:
    std::vector<ThreadSafeQueue<T>> shards_;
    std::atomic<size_t> counter_{0};
    
public:
    explicit ShardedQueue(size_t num_shards) 
        : shards_(num_shards) {}
    
    void push(T value) {
        size_t idx = counter_.fetch_add(1) % shards_.size();
        shards_[idx].push(std::move(value));
    }
    
    std::optional<T> try_pop() {
        for (auto& shard : shards_) {
            if (auto val = shard.try_pop()) {
                return val;
            }
        }
        return std::nullopt;
    }
};
```

**Strategy 2**: Split head and tail locks
```cpp
template<typename T>
class TwoLockQueue {
private:
    struct Node {
        std::shared_ptr<T> data;
        std::unique_ptr<Node> next;
    };
    
    std::mutex head_mutex_;
    std::unique_ptr<Node> head_;
    
    std::mutex tail_mutex_;
    Node* tail_;
    
    Node* get_tail() {
        std::lock_guard<std::mutex> lock(tail_mutex_);
        return tail_;
    }
    
public:
    TwoLockQueue() : head_(new Node), tail_(head_.get()) {}
    
    void push(T value) {
        auto data = std::make_shared<T>(std::move(value));
        auto new_node = std::make_unique<Node>();
        Node* const new_tail = new_node.get();
        
        std::lock_guard<std::mutex> lock(tail_mutex_);
        tail_->data = data;
        tail_->next = std::move(new_node);
        tail_ = new_tail;
    }
    
    std::shared_ptr<T> try_pop() {
        std::lock_guard<std::mutex> lock(head_mutex_);
        if (head_.get() == get_tail()) {
            return nullptr;
        }
        std::shared_ptr<T> result = head_->data;
        head_ = std::move(head_->next);
        return result;
    }
};
```

### 2. Cache Line Considerations

Avoid false sharing by padding:

```cpp
template<typename T>
class CacheAlignedQueue {
private:
    alignas(64) std::queue<T> queue_;
    alignas(64) mutable std::mutex mutex_;
    alignas(64) std::condition_variable cv_;
    
    // Each member on separate cache line
};
```

## Testing Strategy

```cpp
#include <thread>
#include <vector>
#include <cassert>

void test_concurrent_push_pop() {
    ThreadSafeQueue<int> queue;
    constexpr int num_items = 10000;
    constexpr int num_producers = 4;
    constexpr int num_consumers = 4;
    
    std::vector<std::thread> producers;
    std::vector<std::thread> consumers;
    std::atomic<int> sum{0};
    
    // Start producers
    for (int i = 0; i < num_producers; ++i) {
        producers.emplace_back([&queue, i]() {
            for (int j = 0; j < num_items; ++j) {
                queue.push(i * num_items + j);
            }
        });
    }
    
    // Start consumers
    for (int i = 0; i < num_consumers; ++i) {
        consumers.emplace_back([&queue, &sum]() {
            for (int j = 0; j < num_items * num_producers / num_consumers; ++j) {
                sum.fetch_add(queue.pop());
            }
        });
    }
    
    // Wait for completion
    for (auto& t : producers) t.join();
    for (auto& t : consumers) t.join();
    
    // Verify no data loss
    int expected = num_producers * num_items * (num_items - 1) / 2;
    for (int i = 0; i < num_producers; ++i) {
        expected += i * num_items * num_items;
    }
    assert(sum.load() == expected);
}
```

## Common Pitfalls

### 1. Forgetting to Notify

```cpp
// BAD: No notification
void push(T value) {
    std::lock_guard<std::mutex> lock(mutex_);
    queue_.push(std::move(value));
    // Missing cv_.notify_one()!
}
```

### 2. Notifying Under Lock

```cpp
// SUBOPTIMAL: Notify while holding lock
void push(T value) {
    std::lock_guard<std::mutex> lock(mutex_);
    queue_.push(std::move(value));
    cv_.notify_one();  // Still holding lock!
}
```

### 3. Lost Wakeups

```cpp
// BAD: Check before wait without lock
if (queue.empty()) {  // Race: item could be pushed here
    queue.pop();      // Will wait forever if queue was empty
}
```

### 4. Spurious Wakeups Not Handled

```cpp
// BAD: Not using predicate
cv_.wait(lock);  // May wake even if queue still empty
T value = queue_.front();  // Undefined behavior!
```

## Summary Table

| Approach | Pros | Cons | Use Case |
|----------|------|------|----------|
| **Single Mutex** | Simple, safe, easy to debug | High contention under load | Low-moderate concurrency |
| **Two Locks** | Better scalability | More complex | Separate producer/consumer threads |
| **Lock-Free** | Maximum performance | Very complex, hard to debug | High contention, specialized scenarios |
| **Bounded** | Memory bounded | Producers may block | Resource-constrained systems |
| **Sharded** | Reduced contention | Less FIFO guarantee | High throughput required |

## Best Practices

1. **Start simple**: Use mutex-based approach unless profiling shows contention
2. **Use RAII locks**: Always prefer `lock_guard`/`unique_lock` over manual locking
3. **Always use predicates with condition variables**: Guard against spurious wakeups
4. **Notify outside locks**: Reduces unnecessary blocking
5. **Consider move semantics**: Avoid copies for better performance
6. **Test thoroughly**: Use ThreadSanitizer and stress tests
7. **Document thread-safety guarantees**: Make expectations clear
8. **Provide both blocking and non-blocking APIs**: Different use cases need different behavior

## Related Topics

- **Memory ordering**: Understanding `std::memory_order` for lock-free structures
- **Hazard pointers**: Safe memory reclamation in lock-free data structures
- **Producer-consumer pattern**: Design patterns for queue usage
- **Work stealing queues**: Double-ended queues for task scheduling
- **Backpressure handling**: Strategies when producers outpace consumers

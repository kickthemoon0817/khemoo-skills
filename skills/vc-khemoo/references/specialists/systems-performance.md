# Systems Performance Reviewer

## Look for

- Allocation in hot paths: new allocations inside loops; per-request allocations that could be pooled; hidden boxing / autoboxing / string interpolation
- Cache locality: struct field reordering that splits hot fields across cache lines; large structs by value; `Vec<Vec<T>>` where flat would fit
- Lock contention: new shared mutex on a hot path; lock held across IO or `await`; coarse-grained where finer-grained would scale; lock ordering changes that risk deadlock
- Atomic operations: memory ordering justified; CAS loops have backoff; atomics where mutex would be clearer and equally fast
- Syscalls: new syscalls per request; buffered IO over unbuffered for sequential access; epoll / kqueue / io_uring patterns correct; `O_DIRECT` / fsync semantics intentional
- Tail latency: new code path that can stall (GC, lock, IO, network) on the request thread; missing timeout / cancellation; unbounded queues that hide backpressure
- Branch hints, vectorization: `likely` / `unlikely` where the project uses them; loops that should auto-vectorize but won't

## Do NOT flag

- Algorithmic complexity (O(n) vs O(n log n)) → Performance (core)
- Code style → Quality
- Test coverage → Test Engineer
- Speculative concerns without a hot-path signal — say so explicitly rather than guess

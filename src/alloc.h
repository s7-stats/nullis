#ifndef ALLOC_H
#define ALLOC_H

#include <cstdlib>
#include <cstddef>
#include <stdexcept>

/**
 * @file alloc.h
 * @brief Single-allocation arena for short-lived, same-lifetime buffers.
 *
 * Arena allocates one contiguous block of memory upfront via a single
 * `malloc`, then hands out aligned slices from it via pointer bumping.
 * This avoids repeated `malloc`/`free` overhead when several fixed-size
 * buffers are needed for the duration of one function call.
 *
 * Intended use: construct an Arena sized to the total byte budget, call
 * `allocate<T>(n)` for each buffer in sequence, use the buffers, then let
 * the Arena go out of scope. For repeated calls (e.g. bootstrap loops),
 * keep the Arena alive outside the loop and call `reset()` between
 * iterations — this reuses the same block without any additional `malloc`.
 *
 * Constraints:
 * - Allocations are bump-pointer only; individual buffers cannot be freed.
 * - Only trivially constructible types are safe (no constructors are called).
 * - Not copyable or movable; own it by value or via a reference.
 * - Not thread-safe; use one Arena per thread.
 *
 * @example
 * @code
 * // Single-call usage
 * Arena arena(n * (sizeof(double) + sizeof(int)));
 * double* values = arena.allocate<double>(n);
 * int* indices   = arena.allocate<int>(n);
 *
 * // Bootstrap loop usage
 * Arena arena(budget);
 * for (int b = 0; b < B; ++b) {
 *     arena.reset();
 *     double* buf = arena.allocate<double>(n);
 *     // ...
 * }
 * @endcode
 */
class Arena {
private:
    char* memory;
    size_t capacity;
    size_t used;

public:
    /**
     * @brief Construct an Arena with the given byte capacity.
     * @param cap Total bytes to allocate upfront.
     * @throws std::bad_alloc if the underlying `malloc` fails.
     */
    explicit Arena(size_t cap) : capacity(cap), used(0) {
        memory = static_cast<char*>(std::malloc(cap));
        if (!memory) throw std::bad_alloc();
    }

    ~Arena() {
        std::free(memory);
    }

    /// Non-copyable: the raw `malloc` block must have exactly one owner.
    Arena(const Arena&) = delete;
    Arena& operator=(const Arena&) = delete;

    /**
     * @brief Carve out an aligned slice of `n` elements of type `T`.
     *
     * Advances the internal pointer by `n * sizeof(T)` bytes, inserting
     * padding as needed to satisfy `alignof(T)`. Only trivially
     * constructible types are safe — no constructors are called.
     *
     * @tparam T Element type. Must be trivially constructible.
     * @param n  Number of elements to allocate.
     * @return   Pointer to the start of the allocated slice.
     * @throws   std::bad_alloc if the remaining capacity is insufficient.
     */
    template <typename T>
    T* allocate(size_t n) {
        size_t bytes = n * sizeof(T);
        size_t aligned = (used + alignof(T) - 1) & ~(alignof(T) - 1);
        if (aligned + bytes > capacity) throw std::bad_alloc();
        T* ptr = reinterpret_cast<T*>(memory + aligned);
        used = aligned + bytes;
        return ptr;
    }

    /**
     * @brief Reset the arena for reuse without releasing memory.
     *
     * Sets the internal pointer back to zero. All previously allocated
     * slices are invalidated — do not use them after calling `reset()`.
     * Intended for bootstrap or permutation loops where the same buffer
     * layout is needed on every iteration.
     */
    void reset() { used = 0; }
};

#endif /* ALLOC_H */

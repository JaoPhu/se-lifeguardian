#include <stddef.h>

namespace std {
    inline namespace __1 {
        // This symbol is missing in Xcode 26's libc++ but requested by older 
        // precompiled binaries (like MLKit/Firebase). Providing a simple
        // implementation to satisfy the linker.
        size_t __hash_memory(const void* __p, size_t __n) {
            size_t __h = 0;
            const unsigned char* __p2 = (const unsigned char*)__p;
            for (size_t __i = 0; __i < __n; ++__i)
                __h = __h * 31 + __p2[__i];
            return __h;
        }
    }
}

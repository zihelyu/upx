// Copyright (C) Markus Franz Xaver Johannes Oberhumer

#include <stddef.h>

// check ABI - require proper alignment of fundamental types for use in atomics
static_assert(alignof(char) == sizeof(char), "");
static_assert(alignof(short) == sizeof(short), "");
static_assert(alignof(int) == sizeof(int), "");
static_assert(alignof(long) == sizeof(long), "");
static_assert(alignof(ptrdiff_t) == sizeof(ptrdiff_t), "");
static_assert(alignof(size_t) == sizeof(size_t), "");
static_assert(alignof(void *) == sizeof(void *), "");

int main() { return 0; }

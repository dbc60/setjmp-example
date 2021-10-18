/*
 * main.cpp
 *
 * Examples of using setjmp/longjmp with volatile and non-volatile local
 * variables. Compile with your favorite compiler and run to see the
 * the behavior. It can be curious.
 *
 * LICENSE: See end of file for license information.
 */


#include <csetjmp>
#include <iostream>
#include <iterator>  // std::size

#define LOOP_LIMIT 20
#define NONVOLATILE_COUNTER_MAX 0
#define VOLATILE_COUNTER_MAX 9
#define SETJMP2_MAX 18

enum Volatile { VOLATILE_FALSE, VOLATILE_TRUE };

// [[noreturn]] is a C++11 attribute

struct TestSetJmp {
    TestSetJmp(const char*, enum Volatile);
    void Report(int actual, int limit);
    [[noreturn]] void jump(int x);
    jmp_buf buffer;
    const char* name;
    int expected;
    enum Volatile isVolatile1;
};

TestSetJmp::TestSetJmp(const char* test, enum Volatile isVolatile)
    : name(test), isVolatile1(isVolatile) {
    expected = isVolatile1 ? VOLATILE_COUNTER_MAX : NONVOLATILE_COUNTER_MAX;
}

void TestSetJmp::Report(int actual, int limit) {
    const char* varType = isVolatile1 ? "volatile" : "non-volatile";

    std::cout << "Test " << name << " (" << varType << "):" << std::endl;
    std::cout << "    Expected: " << expected << ". Actual: " << actual << "."
              << std::endl;
    if (actual == expected) {
        std::cout << "    Okay." << std::endl;
    } else {
        std::cout << "    Curious." << std::endl;
    }

    std::cout << "    limit: " << limit << std::endl;
}

// Using setjmp/longjmp is an odd way to call a function in a loop
void TestSetJmp::jump(int x) {
    longjmp(buffer, x);
}

struct TestSetJmp2 {
    TestSetJmp2(const char*, enum Volatile, enum Volatile);
    void Report(int actual1, int actual2, int limit);
    [[noreturn]] void jump(int x, int y);
    jmp_buf buffer;
    const char* name;
    int expected1;
    int expected2;
    enum Volatile isVolatile1;
    enum Volatile isVolatile2;
};

TestSetJmp2::TestSetJmp2(const char* test, enum Volatile isVolatile1,
                         enum Volatile isVolatile2)
    : name(test), isVolatile1(isVolatile1), isVolatile2(isVolatile2) {
    if (isVolatile1) {
        expected1 = isVolatile2 ? VOLATILE_COUNTER_MAX : (SETJMP2_MAX - 1);
    } else {
        expected1 = NONVOLATILE_COUNTER_MAX;
    }

    if (isVolatile2) {
        expected2 = isVolatile1 ? VOLATILE_COUNTER_MAX : (SETJMP2_MAX - 1);
    } else {
        expected2 = NONVOLATILE_COUNTER_MAX;
    }
}

void TestSetJmp2::Report(int actual1, int actual2, int limit) {
    const char* varType1 = isVolatile1 ? "volatile" : "non-volatile";
    const char* varType2 = isVolatile2 ? "volatile" : "non-volatile";

    std::cout << "Test " << name << " (" << varType1 << ", " << varType2 << ")"
              << std::endl;
    std::cout << "    Expected1: " << expected1 << ". Actual1: " << actual1
              << "." << std::endl;
    std::cout << "    Expected2: " << expected2 << ". Actual2: " << actual2
              << "." << std::endl;
    if (actual1 == expected1 && actual2 == expected2) {
        std::cout << "    Okay." << std::endl;
    } else {
        std::cout << "    Curious." << std::endl;
    }

    std::cout << "    limit: " << limit << std::endl;
}

void TestSetJmp2::jump(int m, int n) {
    longjmp(buffer, m + n);
}

// For GCC and clang compilers, limit must be volatile, otherwise it's value is
// always 0 when setjmp returns. For VS2019, all local variables are restored
// as long as there is at least one volatile on the stack.
void a0() {
    volatile int limit = 0;
    int c1 = 0;
    TestSetJmp jmp("A0", VOLATILE_FALSE);

    if (setjmp(jmp.buffer) < VOLATILE_COUNTER_MAX && ++limit < LOOP_LIMIT) {
        jmp.jump(++c1);
    }

    jmp.Report(c1, limit);
}

void a1() {
    volatile int limit = 0;
    volatile int c1 = 0;
    TestSetJmp jmp("A1", VOLATILE_TRUE);

    if (setjmp(jmp.buffer) < VOLATILE_COUNTER_MAX && ++limit < LOOP_LIMIT) {
        jmp.jump(++c1);
    }

    jmp.Report(c1, limit);
}

void b0() {
    int c1 = 0;
    int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp("B0", VOLATILE_FALSE, VOLATILE_FALSE);

    if (setjmp(jmp.buffer) < SETJMP2_MAX && ++limit < LOOP_LIMIT) {
        jmp.jump(++c1, ++c2);
    }
    jmp.Report(c1, c2, limit);
}

void b1() {
    int c1 = 0;
    volatile int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp("B1", VOLATILE_FALSE, VOLATILE_TRUE);

    if (setjmp(jmp.buffer) < SETJMP2_MAX && ++limit < LOOP_LIMIT) {
        jmp.jump(++c1, ++c2);
    }
    jmp.Report(c1, c2, limit);
}

void b2() {
    volatile int c1 = 0;
    int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp("B2", VOLATILE_TRUE, VOLATILE_FALSE);

    if (setjmp(jmp.buffer) < SETJMP2_MAX && ++limit < LOOP_LIMIT) {
        jmp.jump(++c1, ++c2);
    }
    jmp.Report(c1, c2, limit);
}

void b3() {
    volatile int c1 = 0;
    volatile int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp("B3", VOLATILE_TRUE, VOLATILE_TRUE);

    if (setjmp(jmp.buffer) < SETJMP2_MAX && ++limit < LOOP_LIMIT) {
        jmp.jump(++c1, ++c2);
    }
    jmp.Report(c1, c2, limit);
}

int main() {
    a0();
    std::cout << "********************" << std::endl << std::endl;

    a1();
    std::cout << "********************" << std::endl << std::endl;

    b0();
    std::cout << "********************" << std::endl << std::endl;

    b1();
    std::cout << "********************" << std::endl << std::endl;

    b2();
    std::cout << "********************" << std::endl << std::endl;

    b3();
}


/*
----------------------------------------------------------------------------
This software is available under 2 licenses --- choose whichever you prefer.
----------------------------------------------------------------------------
ALTERNATIVE A - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute
this software, either in source code form or as a compiled binary, for any
purpose, commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the
public domain. We make this dedication for the benefit of the public at
large and to the detriment of our heirs and successors. We intend this
dedication to be an overt act of relinquishment in perpetuity of all present
and future rights to this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
----------------------------------------------------------------------------
ALTERNATIVE B - MIT License
Copyright (c) 2021 Douglas Cuthbertson
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
----------------------------------------------------------------------------
*/

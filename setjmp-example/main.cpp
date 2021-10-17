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

#include <setjmp.h>
#include <stdio.h>
#include <string.h>

#define LOOP_LIMIT 20
#define EXPECTED_NONVOLATILE 0
#define EXPECTED_VOLATILE 9
#define SETJMP_MAX 18

enum Volatile { VOLATILE_FALSE, VOLATILE_TRUE };

typedef struct TestSetJmp {
    jmp_buf buffer;
    const char* name;
    int expected;
    enum Volatile isVolatile1;
} TestSetJmp, *TestSetJmpPtr;

typedef struct TestSetJmp2 {
    jmp_buf buffer;
    const char* name;
    int expected1;
    int expected2;
    enum Volatile isVolatile1;
    enum Volatile isVolatile2;
} TestSetJmp2, *TestSetJmp2Ptr;

void InitializeTestSetJmp(TestSetJmpPtr jmp, const char* name,
                          enum Volatile isVolatile) {
    memset(&jmp->buffer, 0, sizeof(jmp_buf));
    jmp->name = name;
    jmp->expected = isVolatile ? EXPECTED_VOLATILE : EXPECTED_NONVOLATILE;
    jmp->isVolatile1 = isVolatile;
}

void InitializeTestSetJmp2(TestSetJmp2Ptr jmp, const char* name,
                           enum Volatile isVolatile1,
                           enum Volatile isVolatile2) {
    memset(&jmp->buffer, 0, sizeof(jmp_buf));
    jmp->name = name;
    if (isVolatile1) {
        jmp->expected1 = isVolatile2 ? EXPECTED_VOLATILE : (SETJMP_MAX - 1);
    } else {
        jmp->expected1 = EXPECTED_NONVOLATILE;
    }

    if (isVolatile2) {
        jmp->expected2 = isVolatile1 ? EXPECTED_VOLATILE : (SETJMP_MAX - 1);
    } else {
        jmp->expected2 = EXPECTED_NONVOLATILE;
    }

    jmp->isVolatile1 = isVolatile1;
    jmp->isVolatile2 = isVolatile2;
}

void ReportTestSetJmp(TestSetJmpPtr jmp, int actual, int limit) {
    const char* varType = jmp->isVolatile1 ? "volatile" : "non-volatile";

    printf("Test %s (%s):\n", jmp->name, varType);
    printf("    Expected: %d. Actual: %d.\n", jmp->expected, actual);
    if (actual == jmp->expected) {
        printf("    Okay.\n");
    } else {
        printf("    Curious.\n");
    }

    printf("    limit: %d\n", limit);
}

void ReportTestSetJmp2(TestSetJmp2Ptr jmp, int actual1, int actual2,
                       int limit) {
    const char* varType1 = jmp->isVolatile1 ? "volatile" : "non-volatile";
    const char* varType2 = jmp->isVolatile2 ? "volatile" : "non-volatile";

    printf("Test %s (%s, %s):\n", jmp->name, varType1, varType2);
    printf("    Expected1: %d. Actual1: %d.\n", jmp->expected1, actual1);
    printf("    Expected2: %d. Actual2: %d.\n", jmp->expected2, actual2);
    if (actual1 == jmp->expected1 && actual2 == jmp->expected2) {
        printf("    Okay.\n");
    } else {
        printf("    Curious.\n");
    }

    printf("    limit: %d\n", limit);
}

// Using setjmp/longjmp is an odd way to call a function in a loop
void jump1(TestSetJmpPtr jmp, int x) {
    longjmp(jmp->buffer, x);
}

void jump2(TestSetJmp2Ptr jmp, int m, int n) {
    longjmp(jmp->buffer, m + n);
}

void a0() {
    volatile int limit = 0;
    int c1 = 0;
    TestSetJmp jmp;

    InitializeTestSetJmp(&jmp, "A0", VOLATILE_FALSE);
    if (setjmp(jmp.buffer) < EXPECTED_VOLATILE && ++limit < LOOP_LIMIT) {
        jump1(&jmp, ++c1);
    }

    ReportTestSetJmp(&jmp, c1, limit);
}

void a1() {
    volatile int limit = 0;
    volatile int c1 = 0;
    TestSetJmp jmp;

    InitializeTestSetJmp(&jmp, "A1", VOLATILE_TRUE);

    if (setjmp(jmp.buffer) < EXPECTED_VOLATILE && ++limit < LOOP_LIMIT) {
        jump1(&jmp, ++c1);
    }

    ReportTestSetJmp(&jmp, c1, limit);
}

void b0() {
    int c1 = 0;
    int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp;

    InitializeTestSetJmp2(&jmp, "B0", VOLATILE_FALSE, VOLATILE_FALSE);

    if (setjmp(jmp.buffer) < SETJMP_MAX && ++limit < LOOP_LIMIT) {
        jump2(&jmp, ++c1, ++c2);
    }
    ReportTestSetJmp2(&jmp, c1, c2, limit);
}

void b1() {
    int c1 = 0;
    volatile int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp;

    InitializeTestSetJmp2(&jmp, "B1", VOLATILE_FALSE, VOLATILE_TRUE);

    if (setjmp(jmp.buffer) < SETJMP_MAX && ++limit < LOOP_LIMIT) {
        jump2(&jmp, ++c1, ++c2);
    }
    ReportTestSetJmp2(&jmp, c1, c2, limit);
}

void b2() {
    volatile int c1 = 0;
    int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp;

    InitializeTestSetJmp2(&jmp, "B2", VOLATILE_TRUE, VOLATILE_FALSE);

    if (setjmp(jmp.buffer) < SETJMP_MAX && ++limit < LOOP_LIMIT) {
        jump2(&jmp, ++c1, ++c2);
    }
    ReportTestSetJmp2(&jmp, c1, c2, limit);
}

void b3() {
    volatile int c1 = 0;
    volatile int c2 = 0;
    volatile int limit = 0;
    TestSetJmp2 jmp;

    InitializeTestSetJmp2(&jmp, "B3", VOLATILE_TRUE, VOLATILE_TRUE);

    if (setjmp(jmp.buffer) < SETJMP_MAX && ++limit < LOOP_LIMIT) {
        jump2(&jmp, ++c1, ++c2);
    }
    ReportTestSetJmp2(&jmp, c1, c2, limit);
}

int main() {
    a0();
    printf("********************\n\n");

    a1();
    printf("********************\n\n");

    b0();
    printf("********************\n\n");

    b1();
    printf("********************\n\n");

    b2();
    printf("********************\n\n");

    b3();
}

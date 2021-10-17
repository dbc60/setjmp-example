The purpose of this repo is to better understand when a variable must have the `volatile` attribute applied when `setjmp/longjmp` are in use. The answer is that it depends on which compiler you're using.

Compilers like GCC and clang will restore the values of only `volatile` local variables when `setjmp` returns. On the other hand, Visual Studio 2019 seems to require only one local variable be `volatile` to restore the values of *all* locals.

## Building

There are `.bat` scripts to automate the build. If you have either VS2017 or VS2019 (CE or Pro) or just MSBuild 2017 or 2019 installed, they should find the compiler and set environment variables so the code builds. There's also Visual Studio solution/project files to build 64-bit debug and release versions.

To test this for yourself on Windows, open a command console, navigate to your clone of this repo, and run `build\cmd\build_project.bat` to build a debug version (or `build\cmd\build_project.bat release` to build an optimized version). The scripts create an `x64` directory one level up from the repository and drops the build artifacts there.

I didn't build with GCC and clang locally. [cppreference.com](https://en.cppreference.com/w/) has examples, like one for [longjmp reference page](https://en.cppreference.com/w/cpp/utility/program/longjmp), that can be compiled and run in the webpage. The examples can also be edited and one of several versions of GCC and clang compilers can be chosen. I pasted the code from `main.c` and `main.cpp` into their `longjmp` example, and built and ran them from there.

## My Results

When built with Visual Studio, it didn't matter whether a counter was volatile or not. All that mattered is that at least one variable was volatile. For the GCC and Clang compiles, I had to make `int limit` always volatile to ensure it incremented. I left it that way, so VS produced some "curious" results (at least they differed from what I was expecting).

```txt
Test A0 (non-volatile):
    Expected: 0. Actual: 9.
    Curious.
    limit: 9
********************

Test A1 (volatile):
    Expected: 9. Actual: 9.
    Okay.
    limit: 9
********************

Test B0 (non-volatile, non-volatile):
    Expected1: 0. Actual1: 9.
    Expected2: 0. Actual2: 9.
    Curious.
    limit: 9
********************

Test B1 (non-volatile, volatile):
    Expected1: 0. Actual1: 9.
    Expected2: 17. Actual2: 9.
    Curious.
    limit: 9
********************

Test B2 (volatile, non-volatile):
    Expected1: 17. Actual1: 9.
    Expected2: 0. Actual2: 9.
    Curious.
    limit: 9
********************

Test B3 (volatile, volatile):
    Expected1: 9. Actual1: 9.
    Expected2: 9. Actual2: 9.
    Okay.
    limit: 9
```

On the other hand, both GCC and clang produced no "curiousities".

```txt
Test A0 (non-volatile):
    Expected: 0. Actual: 0.
    Okay.
    limit: 20
********************

Test A1 (volatile):
    Expected: 9. Actual: 9.
    Okay.
    limit: 9
********************

Test B0 (non-volatile, non-volatile):
    Expected1: 0. Actual1: 0.
    Expected2: 0. Actual2: 0.
    Okay.
    limit: 20
********************

Test B1 (non-volatile, volatile):
    Expected1: 0. Actual1: 0.
    Expected2: 17. Actual2: 17.
    Okay.
    limit: 17
********************

Test B2 (volatile, non-volatile):
    Expected1: 17. Actual1: 17.
    Expected2: 0. Actual2: 0.
    Okay.
    limit: 17
********************

Test B3 (volatile, volatile):
    Expected1: 9. Actual1: 9.
    Expected2: 9. Actual2: 9.
    Okay.
    limit: 9
```

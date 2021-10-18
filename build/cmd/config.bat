@echo off

:: LICENSE: See end of file for license information.

:: If there's a command-line argument and it's "release", the build with
:: optimizations. Otherwise, build with debug options.
IF /I "%1" == "optimize" (
    SET BUILD_OPTIMIZED=T
) ELSE (
    SET BUILD_OPTIMIZED=F
)

:: Added _UNICODE and UNICODE so I can use Unicode strings in structs and
:: whatnot.
::
:: Need user32.lib to link MessageBox(), which es used on branch DAY001
:: Need gdi32.lib to link PatBlt(), which es used on branch DAY002
:: 2015.01.25 (Day004) I added /FC to get full path names in diagnostics. It's
:: helpful when using Emacs to code and launch the debugger and executable

:: /GS- turn off security checks because that compile-time option relies on
:: the C runtime library, which we are not using.

:: /Gs[size] The number of bytes that local variables can occupy before
:: a stack probe is initiated. If the /Gs option is specified without a
:: size argument, it is the same as specifying /Gs0

:: /Gm- disable minimal rebuild. We want to build everything. It won't
:: take long.

:: /GR- disable C++ RTTI. We don't need runtime type information.

:: /EHsc enable C++ EH (no SEH exceptions) (/EHs),
:: and  extern "C" defaults to nothrow (/EHc). That is, the compiler assumes
:: that functions declared as extern "C" never throw a C++ exception.

:: /EHa- disable C++ Exception Handling, so we don't have stack unwind code.
:: Casey says we don't need it.


:: /W3 set warning level 3.
:: /W4 set warning level 4. It's better
:: /WX warnings are errors
:: /wd turns off a particular warning
::   /wd4201 - nonstandard extension used : nameless struct/union
::   /wd4100 - 'identifier' : unreferenced formal parameter (this happens a lot while developing code)
::   /wd4189 - 'identifier' : local variable is initialized but not referenced
::   /wd4127 - conditional expression is constant ("do {...} while (0)" in macros)

:: /FC use full pathnames in diagnostics

:: /Od - disable optimizations. The debug mode is good for development

:: /Oi Generate intrinsic functions. Replaces some function calls with
:: intrinsic or otherwise special forms of the function that help your
:: application run faster.

:: /GL whole program optimization. Use the /LTCG linker option to create the
:: output file. /ZI cannot be used with /GL.

:: /I<dir> add to include search path

:: /Fe:<file> name executable file

:: /D<name>{=|#}<text> define macro

:: /Zi enable debugging information
:: /Z7 enable debugging information

:: /link [linker options and libraries] The linker options are
:: documented here: https://msdn.microsoft.com/en-us/library/y0zzbyt4.aspx

:: /nodefaultlib t

:: Note that subsystem version number 5.1 only works with 32-bit builds.
:: The minimum subsystem version number for 64-bit buils is 5.2.
:: /subsystem:windows,5.1 - enable compatibility with Windows XP (5.1)

:: /LTCG link time code generation

:: /STACK:reserve[,commit] stack allocations. The /STACK option sets the size
:: of the stack in bytes. Use this option only when you build an .exe file.

:: DEFINITIONS
::   _UNICODE - 16-bit wide characters
::   UNICODE  - 16-bit wide characters
::   HANDMADE_INTERNAL - 0 = build for public release, 1 = build for developers only
::   HANDMADE_SLOW - 0 = No slow code (like assertion checks) allowed!, 1 = Slow code welcome
::   __ISO_C_VISIBLE - the version of C we are targeting for the math library.
::                     1995 = C95, 1999 = C99, 2011 = C11.

:: BUILD PROPERTIES
:: It's possible to set build properties from the command line using the /p:<Property>=<value>
:: command-line option. For example, to set TargetPlatformVersion to 10.0.10240.0, you would
:: add "/p:TargetPlatformVersion=10.0.10240.0" and possibly
:: "/p:WindowsTargetPlatformVersion=10.0.10240.0". Note that the TargetPlatformVersion setting
:: is optional and allows you to specify the kit version to build with. The default is to use
:: the latest kit.

:: Building Software Using the Universal CRT (VS2015)
:: Use the UniversalCRT_IncludePath property to find the Universal CRT SDK header files.
:: Use one of the following properties to find the linker/library files:
::    UniversalCRT_LibraryPath_x86
::    UniversalCRT_LibraryPath_x64
::    UniversalCRT_LibraryPath_arm

:: Common compiler flags
SET CommonCompilerFlags=/nologo /Zc:wchar_t /Zc:forScope /Zc:inline /Gd /Gm- ^
    /GR- /EHa- /EHsc /Oi /WX /W4 /wd4201 /wd4100 /volatile:iso ^
    /wd4189 /wd4127 /wd4505 /FC /D _UNICODE /D UNICODE /D _WIN32 /D WIN32

::SET CStandardLibraryIncludeFlags=/I"%VSINSTALLDIR%SDK\ScopeCppSDK\SDK\include\ucrt"
::SET CMicrosoftIncludeFlags=/I"%VSINSTALLDIR%SDK\ScopeCppSDK\SDK\include\um" ^
::    /I"%VSINSTALLDIR%SDK\ScopeCppSDK\SDK\include\shared"
::SET CRuntimeIncludeFlags=/I"%VSINSTALLDIR%SDK\ScopeCppSDK\VC\include"

:: Debug and optimized compiler flags
SET CommonCompilerFlagsDEBUG=/MTd  /Zi /Od %CommonCompilerFlags%
SET CommonCompilerFlagsOPTIMIZE=/MT /Zo /O2 /Oi /favor:blend ^
    %CommonCompilerFlags%

:: Preprocessor definitions for a Library build
SET CommonCompilerFlagsBuildLIB=/D _LIB

:: Preprocessor definitions for a DLL build
SET CommonCompilerFlagsBuildDLL=/D _USRDLL /D _WINDLL

:: Choose either Debug or Optimized Compiler Flags
IF "%BUILD_OPTIMIZED%"=="T" (
    SET CommonCompilerFlagsFinal=%CommonCompilerFlagsOPTIMIZE%
) ELSE (
    SET CommonCompilerFlagsFinal=%CommonCompilerFlagsDEBUG%
)


:: Common linker flags
:: set CommonLinkerFlags=/incremental:no /opt:ref user32.lib gdi32.lib winmm.lib
SET CommonLinkerFlags=/nologo /incremental:no /MANIFESTUAC /incremental:no ^
    /opt:ref
SET CommonLinkerFlagsX64=/MACHINE:X64 %CommonLinkerFlags%
SET CommonLinkerFlagsX86=/MACHINE:X86 %CommonLinkerFlags%

:: Choose 32-bit or 64-bit build
:: SET CommonLinkerFlagsFinal=%CommonLinkerFlagsX86%
SET CommonLinkerFlagsFinal=%CommonLinkerFlagsX64%

:: Visual Studio Librarian Options
SET CommonLibrarianFlags=/LTCG /nologo


:: It seems that the minimum subsystem is 5.02 for 64-bit Windows XP. Both "/subsystem:windows,5.1" and /subsystem:windows,5.01"
:: failed with linker warning "LNK4010: invalid subsystem version number 5.1"
:: 32-bit build
:: cl %CommonCompilerFlags% "%DIR_REPO%\src\win32_all.cpp" /link /subsystem:windows,5.02 %CommonLinkerFlagsFinal%

:: 64-bit build
:: set datetime=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
:: set datetime=%datetime: =0%
:: Optimization switches /O2 /Oi /fp:fast


:: ----------------------------------------------------------------------------
:: This software is available under 2 licenses --- choose whichever you prefer.
:: ----------------------------------------------------------------------------
:: ALTERNATIVE A - Public Domain (www.unlicense.org)

:: This is free and unencumbered software released into the public domain.

:: Anyone is free to copy, modify, publish, use, compile, sell, or distribute
:: this software, either in source code form or as a compiled binary, for any
:: purpose, commercial or non-commercial, and by any means.

:: In jurisdictions that recognize copyright laws, the author or authors of this
:: software dedicate any and all copyright interest in the software to the
:: public domain. We make this dedication for the benefit of the public at
:: large and to the detriment of our heirs and successors. We intend this
:: dedication to be an overt act of relinquishment in perpetuity of all present
:: and future rights to this software under copyright law.

:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
:: IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
:: FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
:: AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
:: ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
:: WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
:: ----------------------------------------------------------------------------
:: ALTERNATIVE B - MIT License

:: Copyright (c) 2020 Douglas Cuthbertson

:: Permission is hereby granted, free of charge, to any person obtaining a copy
:: of this software and associated documentation files (the "Software"), to
:: deal in the Software without restriction, including without limitation the
:: rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
:: sell copies of the Software, and to permit persons to whom the Software is
:: furnished to do so, subject to the following conditions:

:: The above copyright notice and this permission notice shall be included in
:: all copies or substantial portions of the Software.

:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
:: IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
:: FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
:: AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
:: LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
:: OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
:: SOFTWARE.
:: ----------------------------------------------------------------------------

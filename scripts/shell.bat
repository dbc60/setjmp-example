@ECHO off
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS

:: LICENSE: See end of file for license information.

:: Argument Descriptions
::
:: Release, Debug, or Test optionally followed by a name for a VS build tool.
:: If no arguments are supplied the defaults are Debug and Test.
:: If the first argument is either Release or Debug, BUILD_TYPE is set
:: accordingly. If Test is the first argument, then BUILD_TYPE is set to Debug
:: and unit tests are also run.
::
:: The next (possibly first) argument sets the path to a build tool,
:: BUILD_TOOLS_PATH. You can specify one of VS2017CE, VS2017Pro, VS2019CE,
:: VS2019Pro, MSBuild2017, MSBuild2019 or an explicit path.
::
:: The default is VS2019CE. Those values are each mapped to a path for a
:: particular version of Visual Studio or MSBuild:
::
:: VS2017CE:
::   "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\"
::
:: VS2017Pro:
::   "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\"
::
:: MSBuild2017:
::   "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build"
::
:: VS2019CE:
::   "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\"
::
:: VS2019Pro:
::   "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\"
::
:: MSBuild2019:
::   "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build"
::
:: When this script runs, it sets these environment variables:
::
::  DIR_SCRIPT: the path to this script without a trailing backslash
::  DIR_BUILD:  the path to this script's parent directory without a trailing
::              backslash
::  DIR_REPO:   the path to the script's grandparent directory (without the
::              trailing backslash) that should be the path to "this" project's
::              repository.
::  VSSolution: the name of the subdirectory under "!DIR_REPO!\builds\" where
::              the Visual Studion solution file is located.
::  BUILD_TYPE: Debug or Release

SET DIR_SCRIPT=%~dp0

:: Remove the trailing slash from DIR_SCRIPT
IF "!DIR_SCRIPT:~-1!" == "\" SET DIR_SCRIPT=!DIR_SCRIPT:~0,-1!

FOR /f "delims=" %%F IN ("!DIR_SCRIPT!") DO (
    SET DIR_BUILD=%%~dpF
)
:: Remove the trailing slash from DIR_BUILD
IF "!DIR_BUILD:~-1!" == "\" SET DIR_BUILD=!DIR_BUILD:~0,-1!

FOR /f "delims=" %%F IN ("!DIR_BUILD!") DO (
    SET DIR_REPO=%%~dpF
)
:: Remove the trailing slash from DIR_REPO
IF "!DIR_REPO:~-1!" == "\" SET DIR_REPO=!DIR_REPO:~0,-1!

TITLE !DIR_REPO!

:: Set a variable for each default path
SET "BUILD_TOOLS_PATH_VS2017CE=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build"
SET "BUILD_TOOLS_PATH_VS2017Pro=C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build"
SET "BUILD_TOOLS_PATH_MSBuild2017=C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build"
SET "BUILD_TOOLS_PATH_VS2019CE=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build"
SET "BUILD_TOOLS_PATH_VS2019Pro=C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build"
SET "BUILD_TOOLS_PATH_MSBuild2019=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build"

IF EXIST "%BUILD_TOOLS_PATH_MSBuild2019%" (
    SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_MSBuild2019%"
    SET VSSOLUTION=vs2019
) ELSE IF EXIST "%BUILD_TOOLS_PATH_VS2019Pro%" (
    SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2019Pro%"
    SET VSSOLUTION=vs2019
) ELSE IF EXIST "%BUILD_TOOLS_PATH_VS2019CE%" (
    SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2019CE%"
    SET VSSOLUTION=vs2019
) ELSE IF EXIST "%BUILD_TOOLS_PATH_MSBuild2017%" (
    SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_MSBuild2017%"
    SET VSSOLUTION=vs2017
) ELSE IF EXIST "%BUILD_TOOLS_PATH_VS2017Pro%" (
    SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2017Pro%"
    SET VSSOLUTION=vs2017
) ELSE IF EXIST "%BUILD_TOOLS_PATH_VS2017CE%" (
    SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2017CE%"
    SET VSSOLUTION=vs2017
)

:: Loop through the command-line arguments, setting the build type to either
:: Debug or Release, and look for one of the build tools.
IF NOT "%1"=="" (
    FOR %%x IN (%*) DO (
        IF /I "%%x"=="x64" (
            SET TARGET_PLATFORM=x64
            SET OUTPUT_DIR=x64
        )
        IF /I "%%x"=="x86" (
            SET TARGET_PLATFORM=Win32
            SET OUTPUT_DIR=
        )
        IF /I "%%x"=="Win32" (
            SET TARGET_PLATFORM=Win32
            SET OUTPUT_DIR=
        )
        IF /I "%%x"=="Debug" SET BUILD_TYPE=Debug
        IF /I "%%x"=="Release" SET BUILD_TYPE=Release
        IF /I "%%x"=="Test" (
            IF /I "!BUILD_TYPE!"=="" (
                SET BUILD_TYPE=Debug
            )
            SET RUN_TESTS=Test
        )
        IF /I "%%x"=="NoTest" (
            SET RUN_TESTS=
        )

:: Overrides in case there's more than one version installed
        IF /I "%%x"=="VS2017CE" (
            SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2017CE%"
            SET VSSOLUTION=vs2017
        ) ELSE IF /I "%%x"=="VS2017Pro" (
            SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2017Pro%"
            SET VSSOLUTION=vs2017
        ) ELSE IF /I "%%x"=="MSBuild2017" (
            SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_MSBuild2017%"
            SET VSSOLUTION=vs2017
        ) ELSE IF /I "%%x"=="VS2019CE" (
            SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2019CE%"
            SET VSSOLUTION=vs2019
        ) ELSE IF /I "%%x"=="VS2019Pro" (
            SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_VS2019Pro%"
            SET VSSOLUTION=vs2019
        ) ELSE IF /I "%%x"=="MSBuild2019" (
            SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH_MSBuild2019%"
            SET VSSOLUTION=vs2019
        )
    )
)

IF "!TARGET_PLATFORM!"=="" (
    SET TARGET_PLATFORM=x64
    SET OUTPUT_DIR=x64
)

:: If the build type wasn't specified, default to Debug and run the tests.
IF "!BUILD_TYPE!"=="" (
    SET BUILD_TYPE=Debug
    IF "!RUN_TESTS!"=="" (
        SET RUN_TESTS=Test
    )
)

:: No known version of Visual Studio was found
IF "!BUILD_TOOLS_PATH!"=="" (
    ECHO Visual Studio is not installed, or is installed on an unexpected path.
    GOTO :EOF
)

:: CALL 'vcvars64.bat' for the selected build tool and check for errors.
IF NOT "!VSINSTALLDIR!" == "" GOTO :EOF
IF /I "!TARGET_PLATFORM!"=="x64" (
    CALL "%BUILD_TOOLS_PATH%\vcvars64.bat"
) ELSE IF /I "!TARGET_PLATFORM!"=="win32" (
    CALL "%BUILD_TOOLS_PATH%\vcvars32.bat"
)

IF "!VSINSTALLDIR!" == "" GOTO badenv


:: Set some variables in the shell
ENDLOCAL && (
    SET "VSINSTALLDIR=%VSINSTALLDIR%"
    SET "PATH=%PATH%"
    SET "VSSOLUTION=%VSSOLUTION%"
    SET "BUILD_TYPE=%BUILD_TYPE%"
    SET "TARGET_PLATFORM=%TARGET_PLATFORM%"
    SET "BUILD_TOOLS_PATH=%BUILD_TOOLS_PATH%"
    SET "OUTPUT_DIR=%OUTPUT_DIR%"
    SET "RUN_TESTS=%RUN_TESTS%"
    SET "Platform=%PLATFORM%"
    SET "INCLUDE=%INCLUDE%"
    SET "LIB=%LIB%"
    SET "LIBPATH=%LIBPATH%"
    SET "UCRTVersion=%UCRTVersion%"
    SET "UniversalCRTSdkDir=%UniversalCRTSdkDir%"
    SET "VCIDEInstallDir=%VCIDEInstallDir%"
    SET "VCINSTALLDIR=%VCINSTALLDIR%"
    SET "VCToolsInstallDir=%VCToolsInstallDir%"
    SET "VCToolsRedistDir=%VCToolsRedistDir%"
    SET "VCToolsVersion=%VCToolsVersion%"
    SET "VisualStudioVersion=%VisualStudioVersion%"
    SET "VS150COMNTOOLS=%VS150COMNTOOLS%"
    SET "VS160COMNTOOLS=%VS160COMNTOOLS%"
    SET "WindowsLibPath=%WindowsLibPath%"
    SET "WindowsSdkBinPath=%WindowsSdkBinPath%"
    SET "WindowsSdkDir=%WindowsSdkDir%"
    SET "WindowsSDKLibVersion=%WindowsSDKLibVersion%"
    SET "WindowsSdkVerBinPath=%WindowsSdkVerBinPath%"
    SET "WindowsSDKVersion=%WindowsSDKVersion%"
    SET "DevEnvDir=%DevEnvDir%"
    SET "ExtensionSdkDir=%ExtensionSdkDir%"
    SET "Framework40Version=%Framework40Version%"
    SET "FrameworkDir=%FrameworkDir%"
    SET "FrameworkDir64=%FrameworkDir64%"
    SET "FrameworkDir32=%FrameworkDir32%"
    SET "FrameworkVersion=%FrameworkVersion%"
    SET "FrameworkVersion64=%FrameworkVersion64%"
    SET "FrameworkVersion32=%FrameworkVersion32%"
)
GOTO :EOF

:badenv
ECHO VSINSTALLDIR is not defined.
ECHO.
ECHO Depending on your Visual Studio edition and install path one of these might work:
ECHO %comspec% /k "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
ECHO or
ECHO %comspec% /k "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsx86_amd64.bat"
ECHO.
GOTO :EOF

:SUBVSVARS
IF /I "!TARGET_PLATFORM!"=="x64" (
    ECHO DBG: SHOULD RUN "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
    ECHO DBG: Running    "%BUILD_TOOLS_PATH%\vcvars64.bat"
    ECHO PERCENT INCLUDE=%INCLUDE%
    ECHO BANG INCLUDE   =!INCLUDE!
    CALL "%BUILD_TOOLS_PATH%\vcvars64.bat"
) ELSE IF /I "!TARGET_PLATFORM!"=="win32" (
    ECHO DBG: SHOULD RUN "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat"
    ECHO DBG: Running    "%BUILD_TOOLS_PATH%\vcvars32.bat"
    CALL "%BUILD_TOOLS_PATH%\vcvars32.bat"
)
GOTO :EOF


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

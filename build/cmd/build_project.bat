@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION ENABLEEXTENSIONS

:: LICENSE: See end of file for license information.

:: Commands are:
::
::      build:      build the project. May be combined with release or debug.
::                  Default is debug.
::      debug:      build the debug configuration.
::      release:    build the release configuration.
::      clean:      clean the (optional) configuration. Default is debug.
::      cleanall:   clean all (both debug and release) configurations.
::
:: build, debug, and release may be combined with clean and cleanall.

SET PROJECT_NAME="setjmp Example"
SET PLATFORM=x64
SET DIR_SCRIPT=%~dp0


:: Remove the trailing directory separator from DIR_SCRIPT
IF "!DIR_SCRIPT:~-1!" == "\" SET DIR_SCRIPT=!DIR_SCRIPT:~0,-1!

FOR /f "delims=" %%F IN ("!DIR_SCRIPT!") DO (
    SET DIR_SCRIPT_PARENT=%%~dpF
)
:: Remove the trailing directory separator from DIR_SCRIPT_PARENT
IF "!DIR_SCRIPT_PARENT:~-1!" == "\" SET DIR_SCRIPT_PARENT=!DIR_SCRIPT_PARENT:~0,-1!

FOR /f "delims=" %%F IN ("!DIR_SCRIPT_PARENT!") DO (
    SET DIR_REPO=%%~dpF
)
:: Remove the trailing directory separator from DIR_REPO
IF "!DIR_REPO:~-1!" == "\" SET DIR_REPO=!DIR_REPO:~0,-1!

FOR /F "delims=" %%F IN ("!DIR_REPO!") DO (
    SET REPO_NAME=%%~nF
)

TITLE !REPO_NAME!

:: Define DIR_REPO_PARENT
FOR /f "delims=" %%F IN ("!DIR_REPO!") DO (
    SET DIR_REPO_PARENT=%%~dpF
)
:: Remove the trailing directory separator from DIR_REPO_PARENT
IF "!DIR_REPO_PARENT:~-1!" == "\" SET DIR_REPO_PARENT=!DIR_REPO_PARENT:~0,-1!

IF "!DIR_WORKSPACE!" == "" (
    SET DIR_WORKSPACE=!DIR_REPO_PARENT!
    SET "DIR_INCLUDE_PATH=!DIR_REPO!\pkg"
) ELSE (
    SET "DIR_INCLUDE_PATH=!DIR_REPO_PARENT!"
)

:: Ensure Visual Studio is available
IF "!VSINSTALLDIR!" == "" CALL !DIR_REPO!\scripts\shell.bat


SET "TEST_CLEAN=;clean;cleanall;"
:: If no argument is provided, then build by default.
IF "%*" == "" (
    SET ARGS=build
) ELSE IF /I "%1" == "build" (
    SET ARGS=%*
) ELSE IF "!TEST_CLEAN:;%*;=!" neq "!TEST_CLEAN!" (
    SET ARGS=%*
) ELSE (
    SET ARGS=build %*
)

GOTO :PROJECTS

:: Set variables (name, clean, build, config) to "T" to run them
:BEGIN_SET_PROJECT
SETLOCAL
SET value=U
SET project=%1
shift
:BEGIN_SET_PROJECTS_LOOP
IF /I "%1" == "%project%" (
    SET value=T
    GOTO :END_SET_PROJECTS_LOOP
)
shift /1
IF "%1" == "" (
    GOTO :END_SET_PROJECTS_LOOP
)

GOTO :BEGIN_SET_PROJECTS_LOOP
:END_SET_PROJECTS_LOOP
ENDLOCAL & SET result=%value%
GOTO :EOF
:END_SET_PROJECT


:dequote
setlocal
SET thestring=%~1%
ENDLOCAL & SET result=%thestring%
GOTO :EOF


:: Build Targets
:PROJECTS
:: build: build a default (debug) configuration
CALL :BEGIN_SET_PROJECT build !ARGS!
SET BUILD_PROJECT=!result!

:: debug: build a debug configuration
CALL :BEGIN_SET_PROJECT debug !ARGS!
SET CONFIG_DEBUG=!result!

:: release: build a release configuration
CALL :BEGIN_SET_PROJECT release !ARGS!
SET CONFIG_RELEASE=!result!

:: Return the name of the project
CALL :BEGIN_SET_PROJECT name !ARGS!
SET name=!result!

:: clean: delete build artifacts from the PLATFORM\CONFIG directory.
CALL :BEGIN_SET_PROJECT clean !ARGS!
SET CLEAN_CONFIG=!result!

:: clean all output directories
CALL :BEGIN_SET_PROJECT cleanall !ARGS!
SET CLEAN_ALL=!result!

:: Display the project name
IF /I "%name%" == "T" (
    CALL :dequote %PROJECT_NAME%
    ECHO !result!
)

:: Configure
IF "!OUTDIR!" == "" (
  IF "%CONFIG_RELEASE%" == "T" (
      CALL !DIR_SCRIPT!\config.bat optimize
      SET OUTDIR=%DIR_WORKSPACE%\!PLATFORM!\!REPO_NAME!\Release
  ) ELSE IF "%CONFIG_DEBUG%"=="T" (
      CALL !DIR_SCRIPT!\config.bat debug
      SET OUTDIR=%DIR_WORKSPACE%\!PLATFORM!\!REPO_NAME!\Debug
  ) ELSE (
      CALL !DIR_SCRIPT!\config.bat debug
      SET OUTDIR=%DIR_WORKSPACE%\!PLATFORM!\!REPO_NAME!\Debug
  )
)

:: Delete the artifacts from the current configuration
IF "%CLEAN_CONFIG%" == "T" (
    IF EXIST !OUTDIR! (
      CALL !DIR_REPO!\libBUTDriver\build\cmd\build_project.bat !ARGS!
      DEL /Q !OUTDIR!
    )
)

:: Delete the build artifacts from the all configurations
IF "%CLEAN_ALL%" == "T" (
    IF EXIST %DIR_WORKSPACE%\!PLATFORM!\!REPO_NAME! RD /S /Q %DIR_WORKSPACE%\!PLATFORM!\!REPO_NAME!
)

:: Build the project
IF "%BUILD_PROJECT%" == "T" (
    IF NOT EXIST !OUTDIR! MD !OUTDIR!
    TITLE !REPO_NAME!
    ECHO.
    CALL :dequote %PROJECT_NAME%
    ECHO Building !result!
    ECHO.

:: Build setjmp-example.exe
    cl %CommonCompilerFlagsFinal% ^
    /I%DIR_INCLUDE_PATH% ^
    "!DIR_REPO!\%REPO_NAME%\main.c"  /Fo:!OUTDIR!\ ^
    /Fd:!OUTDIR!\%REPO_NAME%.pdb /Fe:!OUTDIR!\%REPO_NAME%.exe /link ^
    %CommonLinkerFlagsFinal% /ENTRY:mainCRTStartup

:: Build setjmp-example.exe
    cl %CommonCompilerFlagsFinal% /wd4611 ^
    /I%DIR_INCLUDE_PATH% ^
    "!DIR_REPO!\%REPO_NAME%\main.cpp"  /Fo:!OUTDIR!\ ^
    /Fd:!OUTDIR!\%REPO_NAME%++.pdb /Fe:!OUTDIR!\%REPO_NAME%++.exe /link ^
    %CommonLinkerFlagsFinal% /ENTRY:mainCRTStartup
)

:: Export the environment variables exported by shell.bat
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

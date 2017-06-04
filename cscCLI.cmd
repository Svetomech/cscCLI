@echo off
setlocal

:: PROGRAM EXIT CODES
:: 0 - everything ok
:: 1 - no argument passed or file not found
:: 2 - not a .cs file
:: 3 - compilation error

:: Debug variables
set "me=%~n0"
set "parent=%~dp0"
set "bcd=%cd%"
set "errorlevel=0"

:: Application variables
set "CompanyName=Svetomech"
set "ProductName=cscCLI"
set "ProductVersion=1.9.5.0"
set "ProductRepository=https://github.com/Svetomech/cscCLI"

:: Global variables
set "DesiredAppDirectory=%LocalAppData%\%CompanyName%\%ProductName%"
set "MainConfig=%DesiredAppDirectory%\%ProductName%.txt"
set "VS2015RelativePath=MSBuild\14.0\Bin"
set "VS2017RelativePath=Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\Roslyn"
set "CompilerOptions=/warn:0 /nologo"


:Main:
:: Some initialisation work
set "title=%ProductName% %ProductVersion% by %CompanyName%"
title %title%
color 07
cls
chcp 1252 >nul 2>&1

:: Read settings
if not exist "%DesiredAppDirectory%" mkdir "%DesiredAppDirectory%"
if exist "%MainConfig%" (
    call :LoadSetting "ProductVersion" SettingsProductVersion
)

:: Check version
if "%SettingsProductVersion%" LSS "%ProductVersion%" (
    call :WriteLog "Outdated version, updating now..."
    call :SaveSetting "ProductVersion" "%ProductVersion%"
) else (
    call :WriteLog "Up to date"
)

:: Handle console arguments
set "csFile=%~f1"
set "frameworkChoice=%~2"
set "compilerOptionsExtra=%~3"

if not defined csFile (
    call :WriteLog "Please, drag and drop a C# source file onto me"
    call :Exit "1"
)

call :IsFileValid "%csFile%"
if not "%errorlevel%"=="0" (
    call :WriteLog "Not a C# source file"
    call :Exit "%errorlevel%"
)

call :WriteLog "Found %csFile%"

:: Determine framework root
set "cscDirectory=%SystemRoot%\Microsoft.NET"

call :Is32bitOS
if "%errorlevel%"=="0" (
    set "is32Bit=true"
)
set "errorlevel=0"

if defined is32Bit (
    call :WriteLog "Detected that 32-bit OS is running"
    set "cscDirectory=%cscDirectory%\Framework"
    set "ProgramFiles(x86)=%ProgramFiles%"
) else (
    call :WriteLog "Detected that 64-bit OS is running"
    set "cscDirectory=%cscDirectory%\Framework64"
)

:: Choose framework version
call :PrintFrameworkVersions
if defined frameworkChoice (
    call :WriteLog "Choose an option: %frameworkChoice%"
) else (
    set /p "frameworkChoice=    %me%: Choose an option: "
)

call :IsNumeric "%frameworkChoice%"
if not "%errorlevel%"=="0" (
    call :WriteLineLog "Invalid choice! Enter a number"
    call :Restart "%csFile%"
)
if %frameworkChoice% LSS 1 (
    call :WriteLineLog "Invalid choice! No such option"
    call :Restart "%csFile%"
)
if %frameworkChoice% GTR 5 (
    call :WriteLineLog "Invalid choice! No such option"
    call :Restart "%csFile%"
)

:: Handle user choice
if "%frameworkChoice%"=="1" set "cscDirectory=%cscDirectory%\v2.0.50727"
if "%frameworkChoice%"=="2" set "cscDirectory=%cscDirectory%\v3.5"
if "%frameworkChoice%"=="3" set "cscDirectory=%cscDirectory%\v4.0.30319"
if "%frameworkChoice%"=="4" (
    if defined is32Bit (
        set "cscDirectory=%ProgramFiles(x86)%\%VS2015RelativePath%"
    ) else (
        set "cscDirectory=%ProgramFiles(x86)%\%VS2015RelativePath%\amd64"
    )
)
if "%frameworkChoice%"=="5" set "cscDirectory=%ProgramFiles(x86)%\%VS2017RelativePath%"

if not exist "%cscDirectory%\csc.exe" (
    call :WriteLineLog "Invalid choice! Framework not found"
    call :Restart "%csFile%"
)

:: Compile source file
set "fullCompilerOptions=%CompilerOptions% %compilerOptionsExtra%"
call :GetCsFileName "%csFile%" "%fullCompilerOptions%" csFileName
"%cscDirectory%\csc.exe" %fullCompilerOptions% "%csFile%" >stdout.txt 2>&1 || set "errorlevel=3"

if not "%errorlevel%"=="3" (
    erase stdout.txt
    title %title% ^| SUCCESS
    call :WriteLineLog "Produced %csFileName% in %cd%"
) else (
    title %title% ^| FAILURE
    call :WriteLineLog "Check stdout.txt in %cd%"
)

call :Exit "%errorlevel%"

exit


:: PRIVATE

:IsFileValid: "filePath"
set "errorlevel=0"
echo %~1 | find /i ".cs" >nul 2>&1 || set "errorlevel=2"
if not exist "%~1" set "errorlevel=1"
exit /b %errorlevel%

:PrintFrameworkVersions: ""
echo.
echo %me%: FRAMEWORK VERSION
echo %me%: 1. v2.0  (C# 2.0)
echo %me%: 2. v3.5  (C# 3.0)
echo %me%: 3. v4.0+ (C# 4.0 - C# 5.0)
echo %me%: 4. v4.6  (C# 6.0, VS 2015)
echo %me%: 5. v4.7  (C# 7.0, VS 2017)
echo.
exit /b

:GetCsFileName: "filePath" "compilerOptions" variableName
set "_compilerOptions=%~2"
if not "%_compilerOptions:/out:=%"=="%_compilerOptions%" (
    set "%~3=%_compilerOptions:*/out:=%"
    exit /b
)
if not "%_compilerOptions:/target:library=%"=="%_compilerOptions%" (
    set "%~3=%~n1.dll"
) else (
    set "%~3=%~n1.exe"
)
set "_compilerOptions="
exit /b

:: PUBLIC

:LoadSetting: "key" variableName
for /f "tokens=1  delims=[]" %%n in ('find /i /n "%~1" ^<"%MainConfig%"') do set /a "$n=%%n+1"
for /f "tokens=1* delims=[]" %%a in ('find /n /v "" ^<"%MainConfig%"^|findstr /b "\[%$n%\]"') do set "%~2=%%b"
exit /b

:SaveSetting: "key" "value"
echo %~1    %date% %time%>> "%MainConfig%"
echo %~2>> "%MainConfig%"
echo.>> "%MainConfig%"
exit /b

:WriteLog: "message"
echo %me%: %~1
exit /b

:WriteLineLog: "message"
echo.
echo %me%: %~1
exit /b

:Is32bitOS: ""
set "errorlevel=0"
reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" >nul 2>&1 || set "errorlevel=1"
exit /b %errorlevel%

:IsNumeric: "input"
set "errorlevel=0"
set "_input=%~1"
if "%_input:~0,1%"=="-" set "_input=%_input:~1%"
set "_var="&for /f "delims=0123456789" %%i in ("%_input%") do set "_var=%%i"
if defined _var set "errorlevel=1"
set "_var="
set "_input="
exit /b %errorlevel%

:Restart: "args="
timeout /t 2 >nul 2>&1
goto Main

:Exit: "errorCode"
timeout /t 2 /nobreak >nul 2>&1
exit %~1
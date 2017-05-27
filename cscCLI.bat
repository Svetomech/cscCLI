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
set "ProductVersion=1.7.0.0"
set "ProductRepository=https://github.com/Svetomech/cscCLI"

:: Global variables
set "DesiredAppDirectory=%LocalAppData%\%CompanyName%\%ProductName%"
set "MainConfig=%DesiredAppDirectory%\%ProductName%.txt"


:Main:
:: Some initialisation work
title %ProductName% %ProductVersion% by %CompanyName%
color 07
cls

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
set /p "frameworkChoice=    Choose an option: "

if "%frameworkChoice%"=="1" set "cscDirectory=%cscDirectory%\v2.0.50727"
if "%frameworkChoice%"=="2" set "cscDirectory=%cscDirectory%\v3.5"
if "%frameworkChoice%"=="3" set "cscDirectory=%cscDirectory%\v4.0.30319"
if "%frameworkChoice%"=="4" (
    if defined is32Bit (
        set "cscDirectory=%ProgramFiles(x86)%\MSBuild\14.0\Bin"
    ) else (
        set "cscDirectory=%ProgramFiles(x86)%\MSBuild\14.0\Bin\amd64"
    )
)
if "%frameworkChoice%"=="5" set "cscDirectory=%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\Roslyn"

:: Handle choice 6
call :GetFileNameWithoutExtension "%csFile%" csFileName
if "%frameworkChoice%"=="6" (
    "%cscDirectory%\v2.0.50727\csc.exe" /out:%csFileName%-Net2.0.exe "%csFile%" || set "errorlevel=3"
    "%cscDirectory%\v3.5\csc.exe" /out:%csFileName%-Net3.5.exe "%csFile%" || set "errorlevel=3"
    "%cscDirectory%\v4.0.30319\csc.exe" /out:%csFileName%-Net4.0.exe "%csFile%" || set "errorlevel=3"
    if defined is32Bit (
        "%ProgramFiles(x86)%\MSBuild\14.0\Bin\csc.exe" /out:%csFileName%-Net4.6.exe "%csFile%" || set "errorlevel=3"
    ) else (
        "%ProgramFiles(x86)%\MSBuild\14.0\Bin\amd64\csc.exe" /out:%csFileName%-Net4.6.exe "%csFile%" || set "errorlevel=3"
    )
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\Roslyn\csc.exe" /out:%csFileName%-Net4.7.exe "%csFile%" || set "errorlevel=3"
)
if "%frameworkChoice%"=="6" if not "%errorlevel%"=="3" (
    call :WriteLineLog "Produced %csFileName%-NetX.X.exe in %cd%"
)

if "%frameworkChoice%" LEQ "0" call :Exit "%errorlevel%"
if "%frameworkChoice%" GEQ "6" call :Exit "%errorlevel%"

:: Validate choices 1-5
if not exist "%cscDirectory%\csc.exe" (
    call :WriteLineLog "Invalid choice! Framework not found"
    call :Restart "%csFile%"
)

REM Compiler options
REM CLI
REM VS 2017 support 64-bit (is32Bit)
:: Compile source file
"%cscDirectory%\csc.exe" "%csFile%" || set "errorlevel=3"

if not "%errorlevel%"=="3" (
    call :WriteLineLog "Produced %csFileName%.exe in %cd%"
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
echo FRAMEWORK VERSION
echo 1. v2.0  (C# 2.0)
echo 2. v3.5  (C# 3.0)
echo 3. v4.0+ (C# 4.0 - C# 5.0)
echo 4. v4.6  (C# 6.0, VS 2015)
echo 5. v4.7  (C# 7.0, VS 2017)
echo 6. All
echo.
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

:GetFileName: "filePath" variableName
set "%~2=%~nx1"
exit /b

:GetFileNameWithoutExtension: "filePath" variableName
set "%~2=%~n1"
exit /b

:Restart: "args="
call :WriteLog "Restarting..."
timeout /t 2 >nul 2>&1
goto Main

:Exit: "errorCode"
timeout /t 2 /nobreak >nul 2>&1
exit %~1
@echo off

REM Program exit codes:
REM 0 - everything OK
REM 1 - no argument passed or file not found
REM 2 - not a .cs file

:: Debug variables
set me=%~n0
set parent=%~dp0
set bcd=%cd%
set errorlevel=0

:: Application variables
set CompanyName=Svetomech
set ProductName=cscCLI
set ProductVersion=1.0.0.0
set ProductVersionF=%ProductVersion%

:: Global variables
set DesiredAppDirectory=%LocalAppData%\%CompanyName%\%ProductName%
set MainConfig=%DesiredAppDirectory%\%ProductName%.txt

:Main
:: Some initialisation work
title %ProductName% %ProductVersion% by %CompanyName%
color 07
cls

:: Create settings directory
if not exist "%DesiredAppDirectory%" md "%DesiredAppDirectory%"

:: Read/write(once) settings
if exist "%MainConfig%" (
    call :LoadSetting "ProductVersionF"
) else (
    call :SaveSetting "ProductVersionF" "%ProductVersion%"
)

:: Check version
if "%ProductVersionF%" GEQ "%ProductVersion%" (
    call :WriteLog "Up to date"
) else (
    call :WriteLog "Outdated version"
)

:: Handle console arguments
set filePath=%~f1

if not defined filePath (
    call :WriteLog "Please, do drag and drop a .cs file onto me"
    set errorlevel=1 && goto Exit
)

call :ValidateFilePath "%filePath%"
if not "%errorlevel%" == "0" (
    call :WriteLog "Not a .cs file"
    goto Exit
) else (
    call :WriteLog "Found %filePath%"
)

:: Choose csc version
set cscPath=C:\Windows\Microsoft.NET

echo.
echo TARGET PLATFORM
echo 1. 32-bit
echo 2. 64-bit
REM echo 3. Both
echo.
set /p choice=    Choose an option: 

if "%choice%"=="1" (
    set cscPath=%cscPath%\Framework
) else (
    set cscPath=%cscPath%\Framework64
)

echo.
echo FRAMEWORK VERSION
echo 1. v2.0
echo 2. v3.5
echo 3. v4.0+
if not "%choice%"=="2" echo 4. v4.5+ (C# 6.0)
REM echo 5. All
echo.
set /p choice=    Choose an option: 

if "%choice%"=="1" set cscPath=%cscPath%\v2.0.50727
if "%choice%"=="2" set cscPath=%cscPath%\v3.5
if "%choice%"=="3" set cscPath=%cscPath%\v4.0.30319
if "%choice%"=="4" set cscPath=C:\Program Files (x86)\MSBuild\14.0\Bin

REM TODO: Compiler options
"%cscPath%\csc.exe" "%filePath%"

goto Exit


:: name
:LoadSetting
for /f "tokens=1  delims=[]" %%n in ('find /i /n "%~1" ^<"%MainConfig%"') do set /a "$n=%%n+1"
for /f "tokens=1* delims=[]" %%a in ('find /n /v "" ^<"%MainConfig%"^|findstr /b "\[%$n%\]"') do set "%~1=%%b"
exit /b 0

:: name, value
:SaveSetting
echo %~1>> "%MainConfig%"
echo %~2>> "%MainConfig%"
echo.>> "%MainConfig%"
exit /b 0

:: message
:WriteLog
echo %me%: %~1
exit /b 0

:: filePath
:ValidateFilePath
if not exist "%~1" set errorlevel=1
echo %~1 | findstr /c:".cs" > nul || set errorlevel=2
exit /b %errorlevel%

::
:Exit
timeout 2 > nul
exit /b %errorlevel%
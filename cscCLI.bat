@echo off
setlocal

REM Program exit codes:
REM 0 - everything OK
REM 1 - no argument passed or file not found
REM 2 - not a .cs file
REM 3 - compilation error

:: Debug variables
set "me=%~n0"
set "parent=%~dp0"
set "bcd=%cd%"
set "errorlevel=0"

:: Application variables
set "CompanyName=Svetomech"
set "ProductName=cscCLI"
set "ProductVersion=1.6.0.0"

:: Global variables
set "DesiredAppDirectory=%LocalAppData%\%CompanyName%\%ProductName%"
set "MainConfig=%DesiredAppDirectory%\%ProductName%.txt"

:Main
:: Some initialisation work
title %ProductName% %ProductVersion% by %CompanyName%
color 07
cls

:: Create settings directory
if not exist "%DesiredAppDirectory%" md "%DesiredAppDirectory%"

:: Read settings
if exist "%MainConfig%" (
    call :LoadSetting "ProductVersion" SettingsProductVersion
)

:: Check version
if "%SettingsProductVersion%" GEQ "%ProductVersion%" (
    call :WriteLog "Up to date"
) else (
    call :WriteLog "Outdated version, updating now..."

    call :SaveSetting "ProductVersion" "%ProductVersion%"
)

:: Handle console arguments
set "filePath=%~f1"

if not defined filePath (
    call :WriteLog "Please, do drag and drop a .cs file onto me"
    set "errorlevel=1" && goto Exit
)

call :IsFileValid "%filePath%"
if not "%errorlevel%"=="0" (
    call :WriteLog "Not a .cs file"
    goto Exit
) else (
    call :WriteLog "Found %filePath%"
)

:: Choose csc executable
set "cscPath=C:\Windows\Microsoft.NET"

call :Is32bitOS
if "%errorlevel%"=="0" (
    set "is32bit=True"
) else (
    set "errorlevel=0"
)

if not defined is32bit (
    call :WriteLog "Detected that 64-bit OS is running"
    set "cscPath=%cscPath%\Framework64"
) else (
    call :WriteLog "Detected that 32-bit OS is running"
    set "cscPath=%cscPath%\Framework"
    
    set "ProgramFiles(x86)=%ProgramFiles%"
)

echo.
echo FRAMEWORK VERSION
echo 1. v2.0
echo 2. v3.5
echo 3. v4.0+
echo 4. v4.5+ (C# 6.0)
echo 5. All
echo.
set /p "choice=    Choose an option: "

if "%choice%"=="1" set "cscPath=%cscPath%\v2.0.50727"
if "%choice%"=="2" set "cscPath=%cscPath%\v3.5"
if "%choice%"=="3" set "cscPath=%cscPath%\v4.0.30319"

if "%choice%"=="4" (
    if not defined is32bit (
        set "cscPath=%ProgramFiles(x86)%\MSBuild\14.0\Bin\amd64"
    ) else (
        set "cscPath=%ProgramFiles(x86)%\MSBuild\14.0\Bin"
    )
)

call :GetFileNameWithoutExtension "%filePath%" fileName
if "%choice%"=="5" (
    "%cscPath%\v2.0.50727\csc.exe" /out:%fileName%-Net2.0.exe "%filePath%" || set "errorlevel=3"
    "%cscPath%\v3.5\csc.exe" /out:%fileName%-Net3.5.exe "%filePath%" || set "errorlevel=3"
    "%cscPath%\v4.0.30319\csc.exe" /out:%fileName%-Net4.0.exe "%filePath%" || set "errorlevel=3"
    
    if not defined is32bit (
        "%ProgramFiles(x86)%\MSBuild\14.0\Bin\amd64\csc.exe" /out:%fileName%-Net4.5.exe "%filePath%" || set "errorlevel=3"
    ) else (
        "%ProgramFiles(x86)%\MSBuild\14.0\Bin\csc.exe" /out:%fileName%-Net4.5.exe "%filePath%" || set "errorlevel=3"
    )
)
if "%choice%"=="5" (
    if not "%errorlevel%"=="3" (
        call :WriteLog "Produced %fileName%-NetX.X.exe in %bcd%"
    )
)

if "%choice%" LEQ "0" goto Exit
if "%choice%" GEQ "5" goto Exit

REM TODO: Compiler options
"%cscPath%\csc.exe" "%filePath%" || set "errorlevel=3"

if not "%errorlevel%"=="3" (
    call :WriteLog "Produced %fileName%.exe in %bcd%"
)

goto Exit


:: name, out variableName
:LoadSetting
for /f "tokens=1  delims=[]" %%n in ('find /i /n "%~1" ^<"%MainConfig%"') do set /a "$n=%%n+1"
for /f "tokens=1* delims=[]" %%a in ('find /n /v "" ^<"%MainConfig%"^|findstr /b "\[%$n%\]"') do set "%~2=%%b"
exit /b 0

:: name, value
:SaveSetting
echo %~1    %date% %time%>> "%MainConfig%"
echo %~2>> "%MainConfig%"
echo.>> "%MainConfig%"
exit /b 0

:: message
:WriteLog
echo %me%: %~1
exit /b 0

:: filePath
:IsFileValid
if not exist "%~1" set "errorlevel=1"
echo %~1 | find /i ".cs" > nul || set "errorlevel=2"
exit /b %errorlevel%

:: filePath, out variableName
:GetFileName
set "%~2=%~nx1"
exit /b %errorlevel%

:: filePath, out variableName
:GetFileNameWithoutExtension
set "%~2=%~n1"
exit /b %errorlevel%

::
:Is32bitOS
reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > nul || set "errorlevel=1"
exit /b %errorlevel%

::
:Exit
timeout 2 > nul
exit /b %errorlevel%
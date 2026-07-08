@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ==================================
echo JetBrains Toolbox 확인 및 설치
echo ==================================
echo.


REM ==================================
REM 1. Check PATH
REM ==================================

set "FOUND="

where jetbrains-toolbox.exe >nul 2>&1

if not errorlevel 1 (
    set "FOUND=PATH"
)



REM ==================================
REM 2. Check standard locations
REM ==================================

if exist "%LOCALAPPDATA%\JetBrains\Toolbox\bin\jetbrains-toolbox.exe" (
    set "FOUND=LOCALAPPDATA"
)

if exist "%PROGRAMFILES%\JetBrains\Toolbox\bin\jetbrains-toolbox.exe" (
    set "FOUND=PROGRAMFILES"
)

if exist "%PROGRAMFILES(X86)%\JetBrains\Toolbox\bin\jetbrains-toolbox.exe" (
    set "FOUND=PROGRAMFILES_X86"
)



REM ==================================
REM 3. Check Registry
REM ==================================

if not defined FOUND (

    reg query ^
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall" ^
    /s /f "JetBrains Toolbox" >nul 2>&1

    if not errorlevel 1 (
        set "FOUND=REGISTRY_USER"
    )


    reg query ^
    "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" ^
    /s /f "JetBrains Toolbox" >nul 2>&1

    if not errorlevel 1 (
        set "FOUND=REGISTRY_MACHINE"
    )
)



REM ==================================
REM 4. Check Chocolatey package
REM ==================================

if not defined FOUND (

    choco list --local-only | findstr /I "jetbrainstoolbox" >nul 2>&1

    if not errorlevel 1 (
        set "FOUND=CHOCOLATEY"
    )
)



REM ==================================
REM Result
REM ==================================

if defined FOUND (

    echo.
    echo JetBrains Toolbox가 이미 설치되어 있습니다.
    echo 확인 위치: !FOUND!
    echo 설치를 건너뜁니다.

    pause
    exit /b 0

)



REM ==================================
REM Install
REM ==================================

echo.
echo JetBrains Toolbox가 없습니다.
echo 설치 시작...


choco install jetbrainstoolbox -y


if errorlevel 1 (

    echo.
    echo JetBrains Toolbox 설치 실패
    pause
    exit /b 1

)


echo.
echo JetBrains Toolbox 설치 완료.

pause
exit /b 0
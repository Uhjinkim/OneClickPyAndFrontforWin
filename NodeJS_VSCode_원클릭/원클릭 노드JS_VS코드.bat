@echo off
chcp 949 > nul
setlocal

title Vibe Coding Development Environment Setup

echo.
echo ==========================================
echo   Vibe Coding Development Environment
echo   Installer
echo ==========================================
echo.


:: -------------------------------------------------
:: 관리자 권한 확인
:: -------------------------------------------------

net session >nul 2>&1

if %errorLevel% neq 0 (

    echo 관리자 권한이 필요합니다.
    echo 관리자 권한으로 다시 실행합니다.
    echo.

    powershell ^
    -Command "Start-Process '%~f0' -Verb RunAs"

    exit /b

)


:: -------------------------------------------------
:: PowerShell 파일 확인
:: -------------------------------------------------

set SCRIPT_PATH=%~dp0setup_node_code.ps1


if not exist "%SCRIPT_PATH%" (

    echo.
    echo 오류:
    echo setup_node_code.ps1 파일을 찾을 수 없습니다.
    echo.

    pause
    exit /b 1

)


echo PowerShell 설치 스크립트 실행...
echo.


:: -------------------------------------------------
:: PowerShell 실행
:: -------------------------------------------------

powershell.exe ^
-NoProfile ^
-ExecutionPolicy Bypass ^
-File "%SCRIPT_PATH%"


set RESULT=%ERRORLEVEL%


:: -------------------------------------------------
:: 결과 처리
:: -------------------------------------------------

echo.


if %RESULT% EQU 0 (

    echo ==========================================
    echo 설치가 완료되었습니다.
    echo ==========================================

)
else (

    echo ==========================================
    echo 설치 중 오류가 발생했습니다.
    echo ==========================================
    
    echo.
    echo setup.log 파일을 확인하세요.

)


echo.

pause

exit /b %RESULT%
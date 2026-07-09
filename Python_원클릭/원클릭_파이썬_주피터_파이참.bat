@echo off
chcp 949 > nul

echo ==================================
echo Python 학습 환경 설치 시작
echo ==================================

:: 관리자 권한 확인
net session >nul 2>&1
if %errorLevel% neq 0 (

    echo 관리자 권한이 필요합니다.
    echo 관리자 권한으로 다시 실행합니다.
    echo.

    powershell ^
    -Command "Start-Process '%~f0' -Verb RunAs"

    exit /b

)

powershell.exe ^
    -NoProfile ^
    -ExecutionPolicy Bypass ^
    -Command "$OutputEncoding=[Console]::OutputEncoding=[Text.Encoding]::UTF8; & '%~dp0setup_python_lab.ps1'"

echo.
echo 설치 작업 종료
pause
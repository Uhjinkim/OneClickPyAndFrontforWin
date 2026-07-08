@echo off
chcp 65001 > nul

echo ==================================
echo Starting Python IDLE
echo ==================================


where py >nul 2>&1

if %errorlevel%==0 (

    echo Python Launcher found.

    py -m idlelib

    exit /b
)


echo Python Launcher not found.


where python >nul 2>&1

if %errorlevel%==0 (

    python -m idlelib

    exit /b
)


echo Python installation not found.
pause
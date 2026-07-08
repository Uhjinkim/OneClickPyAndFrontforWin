@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ==================================
echo Starting Jupyter Lab
echo ==================================


set "CONFIG=%~dp0python_lab_config.txt"


if not exist "%CONFIG%" (

    echo Config file not found:
    echo %CONFIG%

    pause
    exit /b 1

)



for /f "tokens=1,* delims==" %%a in ('type "%CONFIG%"') do (

    if "%%a"=="PROJECT" (

        set "WORKSPACE=%%b"

    )

)



if not defined WORKSPACE (

    echo Project folder not found.

    pause
    exit /b 1

)



echo Workspace:
echo !WORKSPACE!



if not exist "!WORKSPACE!" (

    mkdir "!WORKSPACE!"

)



call C:\Miniconda3\Scripts\activate.bat python-study


cd /d "!WORKSPACE!"


echo Starting Jupyter...


start "" /b jupyter lab --no-browser


timeout /t 5 >nul


start "" http://localhost:8888/lab


pause
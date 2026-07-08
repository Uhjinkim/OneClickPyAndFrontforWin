# =========================================================
# 파이썬 + 아나콘다 + 파이참 원클릭 설치
#
# Python Latest + IDLE
# Miniconda + conda-forge
# pandas / Jupyter / PyCharm Environment
#
# Run as Administrator
# =========================================================

$ErrorActionPreference = "Stop"

$Culture = (Get-Culture).Name

# Force Korean UI resources for WinForms dialogs
[System.Threading.Thread]::CurrentThread.CurrentUICulture =
[System.Globalization.CultureInfo]::GetCultureInfo($Culture)


[Console]::OutputEncoding = [System.Text.Encoding]::Default
$OutputEncoding = [System.Text.Encoding]::Default


function Check-Admin {

    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)

    if (!$p.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {

        throw "PowerShell을 관리자로 실행하세요."
    }
}
function Find-PyCharm {

    $SearchPaths = @(
        "$env:LOCALAPPDATA\JetBrains\Toolbox\apps",
        "$env:ProgramFiles\JetBrains",
        "${env:ProgramFiles(x86)}\JetBrains",
        "$env:LOCALAPPDATA\Programs",
        "C:\JetBrains",
        "D:\JetBrains",
        "E:\JetBrains",
        "C:\Program Files\JetBrains",
        "D:\Program Files\JetBrains",

        "C:\Program Files (x86)\JetBrains",
        "D:\Program Files (x86)\JetBrains"
    )


    foreach ($Path in $SearchPaths) {

        if (Test-Path $Path) {

            $Found = Get-ChildItem `
                -Path $Path `
                -Filter "pycharm64.exe" `
                -Recurse `
                -ErrorAction SilentlyContinue |
                Select-Object -First 1


            if ($Found) {

                return $Found.FullName

            }

        }

    }


    return $null
}

function Test-CondaEnv($name) {

    $list = & $Conda env list

    return ($list -match "^$name\s")
}


Check-Admin

# =========================================================
# Check winget
# =========================================================

Write-Host ""
Write-Host "=== winget 확인 ==="

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget이 설치되지 않았습니다. Microsoft Store에서 App Installer를 설치하세요."
}

# =========================================================
# Configuration
# =========================================================

Add-Type -AssemblyName System.Windows.Forms

$MinicondaDir = "C:\Miniconda3"
$CondaCache = "C:\conda_pkgs"

$EnvName = "python-study"



$PyCharmInstaller =
"$env:TEMP\pycharm-community.exe"

$PythonInstaller =
"$env:TEMP\python-latest-installer.exe"

$MinicondaInstaller =
"$env:TEMP\miniconda-installer.exe"

# =========================================================
# 2. Install Python with IDLE
# =========================================================

Write-Host ""
Write-Host "=== Python 확인 ==="

if (Get-Command py -ErrorAction SilentlyContinue) {
    Write-Host "Python 이미 설치되어 있어 건너뜁니다."
}
else {
    Write-Host "Python 설치중..."

    winget install `
        -e `
        --id Python.Python.3.14 `
        --scope machine `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "Python 설치 실패."
    }
}

py --version

# =========================================================
# 3. Install Miniconda
# =========================================================

Write-Host ""
Write-Host "=== Miniconda 확인중 ==="


$Conda = "$MinicondaDir\Scripts\conda.exe"


if (Test-Path $Conda) {

    Write-Host "Miniconda가 이미 설치되어 있어 건너뜁니다."

}
else {

    Write-Host "Miniconda 설치중..."


    Invoke-WebRequest `
        -Uri `
"https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe" `
        -OutFile $MinicondaInstaller


    Start-Process `
        -FilePath $MinicondaInstaller `
        -ArgumentList @(
            "/InstallationType=AllUsers",
            "/RegisterPython=0",
            "/AddToPath=0",
            "/S",
            "/D=$MinicondaDir"
        ) `
        -Wait
}


$Conda = "$MinicondaDir\Scripts\conda.exe"


if (!(Test-Path $Conda)) {

    throw "Conda not found."
}



# =========================================================
# 4. Conda configuration
# =========================================================

Write-Host ""
Write-Host "=== Conda 설정 최적화 ==="


# Remove possible config files containing defaults

$CondaConfigs = @(
    "$env:USERPROFILE\.condarc",
    "$env:USERPROFILE\.conda\.condarc",
    "C:\ProgramData\conda\.condarc",
    "$MinicondaDir\.condarc"
)


foreach ($cfg in $CondaConfigs) {

    if (Test-Path $cfg) {

        Write-Host "삭제중: $cfg"

        Remove-Item $cfg -Force
    }
}



Write-Host ""
Write-Host "=== conda-forge 구성 ==="


# Reset channels

# Remove old channel settings
cmd /c "`"$Conda`" config --remove-key channels >nul 2>&1"

# Add only conda-forge

& $Conda config `
    --add channels conda-forge


& $Conda config `
    --set channel_priority strict


& $Conda config `
    --set auto_activate false


# Package cache

& $Conda config `
    --add pkgs_dirs $CondaCache



Write-Host ""
Write-Host "현재 채널:"

& $Conda config --show channels

# =========================================================
# 5. Create environment
# =========================================================

Write-Host ""
Write-Host "=== Conda 환경 확인 ==="


if (Test-CondaEnv $EnvName) {

    Write-Host "Conda 환경이 존재하므로 건너뜁니다."

}
else {

    Write-Host "환경 생성중..."


    & $Conda create `
        -n $EnvName `
        python=3.12 `
        --override-channels `
        -c conda-forge `
        -y


    if ($LASTEXITCODE -ne 0) {

        throw "Environment creation failed."
    }
}



# =========================================================
# 6. Install packages
# =========================================================

Write-Host ""
Write-Host "=== 데이터 분석 패키지 설치 ==="


Write-Host "패키지 설치중..."

& $Conda install `
    -n $EnvName `
    --override-channels `
    -c conda-forge `
    pandas `
    matplotlib `
    seaborn `
    jupyterlab `
    ipykernel `
    openpyxl `
    -y


if ($LASTEXITCODE -ne 0) {

    throw "Package installation failed."
}



# =========================================================
# 7. Register Jupyter kernel
# =========================================================

Write-Host ""
Write-Host "=== Jupyter kernel 확인 ==="


$KernelPath = "$env:APPDATA\jupyter\kernels\$EnvName"


if (Test-Path $KernelPath) {

    Write-Host "커널이 존재하므로 건너뜁니다."

}
else {

    Write-Host "Jupyter 커널 등록중..."


    & $Conda run `
        -n $EnvName `
        python `
        -m ipykernel install `
        --user `
        --name $EnvName `
        --display-name "Python Study"


    if ($LASTEXITCODE -ne 0) {

        throw "Jupyter kernel registration failed."
    }
}

# =========================================================
# Install PyCharm Community
# =========================================================

Write-Host ""
Write-Host "=== PyCharm 확인 ==="


$PyCharmExe = Find-PyCharm



if ($PyCharmExe) {

    Write-Host "PyCharm이 이미 설치되어 있습니다."
    Write-Host $PyCharmExe

}
else {
    Write-Host "PyCharm을 찾았습니다:"
    Write-Host $PyCharmExe
    Write-Host "PyCharm이 없습니다."
    Write-Host "PyCharm 설치중..."





    Start-Sleep 15



    $PyCharmExe = Find-PyCharm

    winget install `
        -e `
        --id JetBrains.PyCharm.Community `
        --scope machine `
        --accept-package-agreements `
        --accept-source-agreements

    if (!$PyCharmExe) {

        throw "PyCharm 설치 실패."

    }


    Write-Host "PyCharm 설치됨:"
    Write-Host $PyCharmExe

}

# =========================================================
# Select PyCharm project folder
# =========================================================

Write-Host ""
Write-Host "======================================"
Write-Host " PyCharm 실습 폴더 선택"
Write-Host "======================================"
Write-Host ""
Write-Host "Python 실습 파일을 저장할 폴더를 선택하세요."
Write-Host "기존 파일이 있는 폴더를 선택하면 확인 후 진행합니다."
Write-Host ""


$Dialog = New-Object System.Windows.Forms.FolderBrowserDialog

$Dialog.Description =
"PyCharm Python 실습 폴더를 선택하세요."

$Dialog.RootFolder =
[System.Environment+SpecialFolder]::MyComputer

$Dialog.ShowNewFolderButton = $true


$result = $Dialog.ShowDialog()


if ($result -ne "OK") {

    throw "프로젝트 폴더 선택 취소됨."

}


$LabDir = $Dialog.SelectedPath


# =========================================================
# Check existing files
# =========================================================

$ExistingItems = Get-ChildItem `
    -Path $LabDir `
    -Force `
    -ErrorAction SilentlyContinue


if ($ExistingItems.Count -gt 0) {

    $answer = [System.Windows.Forms.MessageBox]::Show(
        "선택한 폴더에 기존 파일이 있습니다.`n`n기존 파일은 유지됩니다.`nPyCharm 프로젝트 설정을 추가할 수 있습니다.`n`n계속 진행할까요?",
        "기존 폴더 확인",
        "YesNo",
        "Warning"
    )


    if ($answer -ne "Yes") {

        throw "프로젝트 폴더 선택 취소됨."

    }
}


Write-Host ""
Write-Host "선택된 폴더:"
Write-Host $LabDir

# ==================================
# Save project folder setting
# ==================================

$ConfigFile = Join-Path $PSScriptRoot "python_lab_config.txt"

"PROJECT=$LabDir" | Out-File `
    -FilePath $ConfigFile `
    -Encoding UTF8


# =========================================================
# Create PyCharm project files
# =========================================================

$IdeaDir = Join-Path $LabDir ".idea"


# Create .idea only if missing

if (!(Test-Path $IdeaDir)) {

    New-Item `
        -ItemType Directory `
        -Path $IdeaDir `
        | Out-Null

}


# Create main.py only if missing

$MainFile = Join-Path $LabDir "main.py"


if (!(Test-Path $MainFile)) {

@"
print("Python Learning Lab")

import sys

print("Python version:")
print(sys.version)

print("Interpreter:")
print(sys.executable)
"@ | Out-File `
    $MainFile `
    -Encoding UTF8

}
else {

    Write-Host "main.py가 이미 존재하므로 건너뜁니다."

}
# =========================================================
# Create PyCharm interpreter setting
# =========================================================

$MiscFile = Join-Path $IdeaDir "misc.xml"


if (!(Test-Path $MiscFile)) {

    Write-Host "PyCharm 인터프리터 설정 생성중..."


    $PythonInterpreter =
    "$MinicondaDir\envs\$EnvName\python.exe"


@"
<project version="4">
  <component name="ProjectRootManager"
    version="2"
    project-jdk-name="$EnvName"
    project-jdk-type="Python SDK">
  </component>
</project>
"@ | Out-File `
    $MiscFile `
    -Encoding UTF8

}
else {

    Write-Host "PyCharm 설정이 이미 존재하므로 건너뜁니다."

}

# =========================================================
# 8. Verification
# =========================================================

Write-Host ""
Write-Host "=== Verification ==="


py --version


& $Conda run `
    -n $EnvName `
    python `
    -c `
    "import pandas; print('pandas OK')"

if ($LASTEXITCODE -ne 0) {

    throw "Verification 실패."
}

# =========================================================
# Create PyCharm Shortcuts
# =========================================================

Write-Host ""
Write-Host "=== PyCharm 바로가기 생성 ==="


if (!(Test-Path $PyCharmExe)) {

    throw "PyCharm 실행 파일이 없습니다: $PyCharmExe"

}


# 배치/스크립트가 있는 폴더

$ScriptFolder = Split-Path `
    -Parent `
    $MyInvocation.MyCommand.Path



# 바탕화면 실제 경로

$DesktopFolder =
[Environment]::GetFolderPath("Desktop")



$ShortcutLocations = @(
    $ScriptFolder,
    $DesktopFolder
)



$Shell = New-Object -ComObject WScript.Shell



foreach ($Location in $ShortcutLocations) {


    if (Test-Path $Location) {


        $ShortcutPath =
        Join-Path `
        $Location `
        "PyCharm.lnk"



        $Link =
        $Shell.CreateShortcut($ShortcutPath)


        $Link.TargetPath =
        $PyCharmExe


        $Link.WorkingDirectory =
        Split-Path $PyCharmExe



        $Link.IconLocation =
        $PyCharmExe


        $Link.Save()



        Write-Host "생성된 경로:"
        Write-Host $ShortcutPath

    }

}

Write-Host ""
Write-Host "===================================="
Write-Host " 세팅 완료"
Write-Host "===================================="

Write-Host ""
Write-Host "IDLE:"
Write-Host " IDLE 배치 파일 -> IDLE"

Write-Host ""
Write-Host "Conda 환경:"
Write-Host $EnvName

Write-Host ""
Write-Host "PyCharm 인터프리터:"
Write-Host "$MinicondaDir\envs\$EnvName\python.exe"

Write-Host ""
Write-Host "Jupyter:"
Write-Host "conda run -n $EnvName jupyter lab"

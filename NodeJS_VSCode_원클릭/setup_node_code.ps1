# ==========================================================
# setup.ps1
# Vibe Coding 교육 환경 설치
# STEP 1
# ==========================================================

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# UTF-8 출력
[Console]::OutputEncoding = [System.Text.Encoding]::Default
$OutputEncoding = [System.Text.Encoding]::Default

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Vibe Coding 교육 환경 설치"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

#-----------------------------------------------------------
# 로그
#-----------------------------------------------------------

$LogFile = Join-Path $PSScriptRoot "setup.log"

function Write-Log {

    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $line = "[$time][$Level] $Message"

    Write-Host $line

    Add-Content `
        -Path $LogFile `
        -Value $line `
        -Encoding UTF8
}

Write-Log "설치 시작"

#-----------------------------------------------------------
# 관리자 권한 확인
#-----------------------------------------------------------

function Test-Administrator {

    $identity =
        [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal =
        New-Object Security.Principal.WindowsPrincipal($identity)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

}

if (-not (Test-Administrator)) {

    Write-Log "관리자 권한이 필요합니다." "ERROR"

    Write-Host ""
    Write-Host "관리자 권한으로 실행해 주세요." -ForegroundColor Red
    Pause

    exit
}

Write-Log "관리자 권한 확인 완료"

#-----------------------------------------------------------
# 인터넷 확인
#-----------------------------------------------------------

function Test-Internet {

    try {

        $client = New-Object System.Net.Http.HttpClient
        $client.Timeout = [TimeSpan]::FromSeconds(5)

        $response = $client.GetAsync("https://www.microsoft.com").Result

        $client.Dispose()

        return $response.IsSuccessStatusCode

    }
    catch {

        return $false

    }

}

Write-Log "인터넷 연결 확인 완료"

#-----------------------------------------------------------
# winget 확인
#-----------------------------------------------------------

function Test-Winget {

    return $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

}

if (!(Test-Winget)) {

    Write-Log "winget이 설치되어 있지 않습니다." "ERROR"

    Write-Host ""
    Write-Host "Microsoft App Installer를 설치하세요."
    Write-Host ""

    Pause

    exit

}

Write-Log "winget 확인 완료"

#-----------------------------------------------------------
# 공통 함수
#-----------------------------------------------------------

function Write-Step {

    param($Message)

    Write-Host ""
    Write-Host "--------------------------------------------------" `
        -ForegroundColor Yellow

    Write-Host $Message `
        -ForegroundColor Yellow

    Write-Host "--------------------------------------------------" `
        -ForegroundColor Yellow

}

function Test-Command {

    param(
        [string]$Command
    )

    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)

}

Write-Step "STEP 1 완료"

Write-Log "STEP 1 완료"

Write-Host ""
Write-Host "다음 단계에서는 Node.js와 VS Code 설치를 진행합니다." `
    -ForegroundColor Green

#==========================================================
# STEP 2
# Node.js / npm / VS Code 설치
#==========================================================

Write-Step "STEP 2 - 개발도구 설치"

function Install-WingetPackage {

    param(
        [string]$PackageId,
        [string]$DisplayName
    )

    Write-Host "$DisplayName 설치 중..."
    Write-Log "$DisplayName 설치 시작"

    winget install `
        --id $PackageId `
        -e `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Log "$DisplayName 설치 실패" "ERROR"
        throw "$DisplayName 설치 실패"
    }

    Write-Log "$DisplayName 설치 완료"
}

#----------------------------------------------------------
# Node.js
#----------------------------------------------------------

if (Test-Command "node") {

    $version = node -v

    Write-Host "Node.js : $version"

    Write-Log "Node.js 이미 설치 ($version)"

}
else {

    Install-WingetPackage `
        "OpenJS.NodeJS.LTS" `
        "Node.js LTS"

}

#----------------------------------------------------------
# npm
#----------------------------------------------------------

for ($i = 0; $i -lt 10; $i++) {

    $env:Path =
        [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
        [Environment]::GetEnvironmentVariable("Path","User")

    if (Test-Command "node" -and Test-Command "npm") {
        break
    }

    Start-Sleep -Seconds 1
}

if (Test-Command "npm") {

    $version = npm -v

    Write-Host "npm : $version"

    Write-Log "npm 확인 ($version)"

}
else {

    throw "npm을 찾을 수 없습니다."

}

#----------------------------------------------------------
# VS Code
#----------------------------------------------------------

if (Test-Command "code") {

    Write-Host "VS Code : 설치됨"

    Write-Log "VS Code 이미 설치"

}
else {

    Install-WingetPackage `
        "Microsoft.VisualStudioCode" `
        "Visual Studio Code"

}

#----------------------------------------------------------
# PATH 갱신
#----------------------------------------------------------

$env:Path = [System.Environment]::GetEnvironmentVariable(
    "Path",
    "Machine"
) + ";" +
[System.Environment]::GetEnvironmentVariable(
    "Path",
    "User"
)

#----------------------------------------------------------
# code 명령 확인
#----------------------------------------------------------

if (!(Test-Command "code")) {

    $possible = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin",
        "$env:ProgramFiles\Microsoft VS Code\bin",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\bin"
    )

    foreach ($dir in $possible) {

        if (Test-Path "$dir\code.cmd") {

            $env:Path += ";$dir"

        }

    }

}

if (!(Test-Command "code")) {

    throw "VS Code CLI(code)를 찾을 수 없습니다."

}

#----------------------------------------------------------
# 설치 결과 출력
#----------------------------------------------------------

Write-Host ""
Write-Host "설치 확인"

Write-Host "---------------------------"

Write-Host ("Node : " + (node -v))
Write-Host ("npm  : " + (npm -v))

$codeVersion = code --version | Select-Object -First 1
Write-Host ("Code : " + $codeVersion)

Write-Host "---------------------------"

Write-Log "STEP 2 완료"

#==========================================================
# STEP 3
# 실습 폴더 선택 및 VS Code 환경 설정
#==========================================================

Write-Step "STEP 3 - 실습 폴더 설정"


#----------------------------------------------------------
# 폴더 선택 함수
#----------------------------------------------------------

function Select-ProjectFolder {

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog

    $dialog.Description =
        "바이브코딩 실습 폴더를 선택하세요."

    $dialog.ShowNewFolderButton = $true


    if ($dialog.ShowDialog() -eq "OK") {

        return $dialog.SelectedPath

    }

    return $null

}


#----------------------------------------------------------
# 실습 폴더 선택
#----------------------------------------------------------

$ProjectFolder = Select-ProjectFolder


if ([string]::IsNullOrWhiteSpace($ProjectFolder)) {

    Write-Log "실습 폴더 선택 취소" "ERROR"

    Write-Host ""
    Write-Host "실습 폴더가 선택되지 않았습니다."
        -ForegroundColor Red

    exit

}


Write-Log "실습 폴더 선택 : $ProjectFolder"


#----------------------------------------------------------
# 폴더 생성 확인
#----------------------------------------------------------

if (!(Test-Path $ProjectFolder)) {

    New-Item `
        -ItemType Directory `
        -Path $ProjectFolder `
        | Out-Null

}


#----------------------------------------------------------
# VS Code 설정 폴더
#----------------------------------------------------------

$VSCodeFolder =
    Join-Path $ProjectFolder ".vscode"


if (!(Test-Path $VSCodeFolder)) {

    New-Item `
        -ItemType Directory `
        -Path $VSCodeFolder `
        | Out-Null

}


#----------------------------------------------------------
# VS Code Workspace 설정
#----------------------------------------------------------

$SettingsFile =
    Join-Path $VSCodeFolder "settings.json"


$Settings = @{
    
    # 저장 자동화
    "files.autoSave" = "afterDelay"

    # 마지막 프로젝트 복원
    "window.restoreWindows" = "all"

    # 포맷 설정
    "editor.formatOnSave" = $true

    # ESLint
    "eslint.validate" = @(
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact"
    )

    # 교육 환경에서 Trust 팝업 방지
    "security.workspace.trust.enabled" = $false

}


$Json =
    $Settings |
    ConvertTo-Json -Depth 10


Set-Content `
    -Path $SettingsFile `
    -Value $Json `
    -Encoding UTF8


Write-Log "VS Code 설정 생성 완료"


#----------------------------------------------------------
# VS Code 최근 프로젝트 등록
#----------------------------------------------------------

$StoragePath =
    Join-Path `
    $env:APPDATA `
    "Code\User"


if (!(Test-Path $StoragePath)) {

    New-Item `
        -ItemType Directory `
        -Path $StoragePath `
        | Out-Null

}


# 사용자 설정 생성

$UserSettings =
    Join-Path `
    $StoragePath `
    "settings.json"


if (!(Test-Path $UserSettings)) {

    "{}" |
    Set-Content `
        -Path $UserSettings `
        -Encoding UTF8

}


Write-Log "VS Code 사용자 설정 위치 확인"


#----------------------------------------------------------
# 실습 정보 저장
#----------------------------------------------------------

$ConfigFile =
    Join-Path `
    $PSScriptRoot `
    "install-config.json"


@{
    ProjectFolder = $ProjectFolder
    CreatedAt = (Get-Date)
} |
ConvertTo-Json |
Set-Content `
    -Path $ConfigFile `
    -Encoding UTF8


Write-Host ""
Write-Host "실습 폴더:"
Write-Host $ProjectFolder `
    -ForegroundColor Green


Write-Log "STEP 3 완료"

#==========================================================
# STEP 4
# VS Code Extension / npm 설정 / 실행
#==========================================================

Write-Step "STEP 4 - 개발 환경 마무리"


#----------------------------------------------------------
# VS Code Extension 설치
#----------------------------------------------------------

function Install-VSCodeExtension {

    param(
        [string]$ExtensionId
    )


    Write-Host ""
    Write-Host "Extension 확인 : $ExtensionId"


    try {

        $installed =
            code --list-extensions |
            Select-String `
                -SimpleMatch `
                $ExtensionId


        if ($installed) {

            Write-Host "이미 설치됨"
                -ForegroundColor Green

            Write-Log "Extension 이미 설치 : $ExtensionId"

            return

        }


        code `
            --install-extension `
            $ExtensionId `
            --force


        Write-Log "Extension 설치 완료 : $ExtensionId"


    }

    catch {

        Write-Log `
            "Extension 설치 실패 : $ExtensionId" `
            "ERROR"

    }

}



$Extensions = @(

    "dbaeumer.vscode-eslint",

    "esbenp.prettier-vscode",

    "formulahendry.auto-rename-tag",

    "christian-kohler.path-intellisense"

)


foreach ($ext in $Extensions) {

    Install-VSCodeExtension $ext

}



#----------------------------------------------------------
# npm 교육 환경 설정
#----------------------------------------------------------

Write-Step "npm 설정"


npm config set fund false

npm config set audit false

npm config set update-notifier false


Write-Log "npm 교육용 설정 완료"


#----------------------------------------------------------
# VS Code 실행
#----------------------------------------------------------

Write-Step "VS Code 실행"



Start-Process `
    "code" `
    -ArgumentList "`"$ProjectFolder`""


Write-Log "VS Code 실행"



#----------------------------------------------------------
# 최종 결과
#----------------------------------------------------------

Write-Host ""

Write-Host "======================================" `
    -ForegroundColor Cyan

Write-Host " 설치 완료!"

Write-Host "======================================" `
    -ForegroundColor Cyan


Write-Host ""

Write-Host "Node:"
node -v


Write-Host "npm:"
npm -v


Write-Host "VS Code:"
code --version |
Select-Object -First 1


Write-Host ""

Write-Host "실습 폴더:"
Write-Host $ProjectFolder `
    -ForegroundColor Green


Write-Log "전체 설치 완료"



Write-Host ""

Write-Host "아무 키나 누르면 종료됩니다."

Pause
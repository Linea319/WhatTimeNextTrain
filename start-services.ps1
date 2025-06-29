# WhatTimeNextTrain 開発環境起動スクリプト (Windows)
# 
# このスクリプトはバックエンドとフロントエンドを同時に起動します

#文字コードをUTF-8に設定
#chcp 65001

param(
    [switch]$StopServices,
    [switch]$RestartServices
)

$ErrorActionPreference = "Stop"

# プロジェクトのルートディレクトリを取得
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendPath = Join-Path $ProjectRoot "backend"
$FrontendPath = Join-Path $ProjectRoot "frontend"

# ログファイルのパス
$LogDir = Join-Path $ProjectRoot "logs"
$BackendLogFile = Join-Path $LogDir "backend.log"
$BackendErrorLogFile = Join-Path $LogDir "backend-error.log"
$FrontendLogFile = Join-Path $LogDir "frontend.log"
$FrontendErrorLogFile = Join-Path $LogDir "frontend-error.log"

# ログディレクトリを作成
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# 使用可能な色の一覧
$AllowedColors = @(
    "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray",
    "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White"
)

function Write-ColorOutput(){
    param([string]$Message = ".", [string]$Color = "White")
    if ($AllowedColors -notcontains $Color) {
        $Color = "White"
    }
    Write-Host $Message -ForegroundColor $Color
}

function Stop-Services {
    Write-ColorOutput "🛑 サービスを停止中..." "Yellow"
    
    # Pythonプロセスを停止（より広範囲な検索）
    $pythonProcesses = Get-Process -Name "python*" -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -like "*python*"
    }
    
    if ($pythonProcesses) {
        # 各プロセスのコマンドラインを確認してrun.pyを実行しているものを特定
        $targetProcesses = @()
        foreach ($proc in $pythonProcesses) {
            try {
                $commandLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
                if ($commandLine -and $commandLine -like "*run.py*") {
                    $targetProcesses += $proc
                    Write-ColorOutput "  対象プロセス発見: PID $($proc.Id) - $commandLine" "Gray"
                }
            } catch {
                # WMI取得に失敗した場合はスキップ
            }
        }
        
        if ($targetProcesses.Count -gt 0) {
            $targetProcesses | Stop-Process -Force
            Write-ColorOutput "✅ バックエンド (Python) を停止しました ($($targetProcesses.Count)個のプロセス)" "Green"
        } else {
            Write-ColorOutput "ℹ️ run.pyを実行中のPythonプロセスが見つかりませんでした" "Yellow"
        }
    } else {
        Write-ColorOutput "ℹ️ 実行中のPythonプロセスが見つかりませんでした" "Yellow"
    }
    
    # Node.jsプロセスを停止
    $nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
    if ($nodeProcesses) {
        $nodeProcesses | Stop-Process -Force
        Write-ColorOutput "✅ フロントエンド (Node.js) を停止しました" "Green"
    } else {
        Write-ColorOutput "ℹ️ 実行中のNode.jsプロセスが見つかりませんでした" "Yellow"
    }
    
    Write-ColorOutput "🏁 サービス停止処理が完了しました" "Green"
}

function Start-Backend {
    Write-ColorOutput "🚀 バックエンド (Python + Flask) を起動中..." "Cyan"
    
    # バックエンドディレクトリの存在確認
    if (-not (Test-Path $BackendPath)) {
        throw "❌ バックエンドディレクトリが見つかりません: $BackendPath"
    }
    
    # Pythonの実行可能ファイルを検索
    $PythonExe = $null
    $PythonCandidates = @(
        "python",
        "python3",
        "python3.11",
        "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WindowsApps\python3.11.exe"
    )
    
    foreach ($candidate in $PythonCandidates) {
        try {
            $version = & $candidate --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                $PythonExe = $candidate
                Write-ColorOutput "✅ Python found: $candidate ($version)" "Green"
                break
            }
        } catch {
            continue
        }
    }
    
    if (-not $PythonExe) {
        throw "❌ Pythonが見つかりません。Pythonをインストールしてください。"
    }
    
    # バックエンドを別プロセスで起動（ウィンドウを表示）
    $BackendJob = Start-Process -FilePath $PythonExe -ArgumentList "run.py" -WorkingDirectory $BackendPath -PassThru
    
    # サーバーの起動を待機
    Write-ColorOutput "⏳ バックエンドサーバーの起動を待機中..." "Yellow"
    $maxRetries = 30
    $retryCount = 0
    
    do {
        Start-Sleep -Seconds 1
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -Method GET -TimeoutSec 4 -ErrorAction SilentlyContinue
            if ($response) {
                Write-ColorOutput "✅ バックエンドサーバーが起動しました (http://localhost:5000)" "Green"
                return $BackendJob
            }
        } catch {
            # 接続失敗は正常（まだ起動中）
        }
        $retryCount++
    } while ($retryCount -lt $maxRetries)
    
    throw "❌ バックエンドサーバーの起動に失敗しました"
}

function Start-Frontend {
    Write-ColorOutput "🚀 フロントエンド (Vue.js + Vite) を起動中..." "Cyan"
    
    # フロントエンドディレクトリの存在確認
    if (-not (Test-Path $FrontendPath)) {
        throw "❌ フロントエンドディレクトリが見つかりません: $FrontendPath"
    }
    
    # Node.jsの存在確認
    try {
        $nodeVersion = & node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Node.js found: $nodeVersion" "Green"
        } else {
            throw "Node.js not found"
        }
    } catch {
        throw "❌ Node.jsが見つかりません。Node.jsをインストールしてください。"
    }
    
    # npmの存在確認
    try {
        $npmVersion = & npm --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ npm found: $npmVersion" "Green"
        } else {
            throw "npm not found"
        }
    } catch {
        throw "❌ npmが見つかりません。Node.jsを再インストールしてください。"
    }
    
    # package.jsonの存在確認
    $PackageJsonPath = Join-Path $FrontendPath "package.json"
    if (-not (Test-Path $PackageJsonPath)) {
        throw "❌ package.jsonが見つかりません: $PackageJsonPath"
    }
    
    # node_modulesの存在確認
    $NodeModulesPath = Join-Path $FrontendPath "node_modules"
    if (-not (Test-Path $NodeModulesPath)) {
        Write-ColorOutput "📦 依存関係をインストール中..." "Yellow"
        
        # npm install を同期実行
        $installProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm install" -WorkingDirectory $FrontendPath -Wait -PassThru -NoNewWindow
        if ($installProcess.ExitCode -ne 0) {
            throw "❌ npm install に失敗しました"
        }
        Write-ColorOutput "✅ 依存関係のインストールが完了しました" "Green"
    }
    
    # フロントエンドを別プロセスで起動（ウィンドウを表示）
    $FrontendJob = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm run dev" -WorkingDirectory $FrontendPath -PassThru
    
    # サーバーの起動を待機
    Write-ColorOutput "⏳ フロントエンドサーバーの起動を待機中..." "Yellow"
    $maxRetries = 30
    $retryCount = 0
    
    do {
        Start-Sleep -Seconds 2
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-ColorOutput "✅ フロントエンドサーバーが起動しました (http://localhost:3000)" "Green"
                return $FrontendJob
            }
        } catch {
            # 接続失敗は正常（まだ起動中）
        }
        $retryCount++
    } while ($retryCount -lt $maxRetries)
    
    Write-ColorOutput "⚠️ フロントエンドサーバーの確認に失敗しましたが、起動は継続します" "Yellow"
    return $FrontendJob
}

function Main {
    try {
        Write-ColorOutput "🚃 WhatTimeNextTrain 起動スクリプト (Windows)" "Magenta"
        Write-ColorOutput "=" * 50 "Magenta"
        
        if ($StopServices) {
            Stop-Services
            return
        }
        
        if ($RestartServices) {
            Stop-Services
            Start-Sleep -Seconds 2
        }
        
        # サービス起動
        $BackendJob = Start-Backend
        Start-Sleep -Seconds 3
        $FrontendJob = Start-Frontend
        
        Write-ColorOutput "" "White"
        Write-ColorOutput "🎉 全てのサービスが起動しました！" "Green"
        Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Green"
        Write-ColorOutput "🌐 フロントエンド: http://localhost:3000" "Cyan"
        Write-ColorOutput "🔧 バックエンドAPI: http://localhost:5000" "Cyan"
        Write-ColorOutput "📋 ヘルスチェック: http://localhost:5000/api/health" "Cyan"
        Write-ColorOutput "" "White"
        Write-ColorOutput "📁 ログファイル:" "Yellow"
        Write-ColorOutput "  Backend:  $BackendLogFile" "Gray"
        Write-ColorOutput "  Frontend: $FrontendLogFile" "Gray"
        Write-ColorOutput "" "White"
        Write-ColorOutput "⏹️  サービスを停止するには: .\start-services.ps1 -StopServices" "Yellow"
        Write-ColorOutput "🔄 サービスを再起動するには: .\start-services.ps1 -RestartServices" "Yellow"
        Write-ColorOutput "" "White"
        Write-ColorOutput "Ctrl+C で このスクリプトを終了できます (サービスは継続実行されます)" "Gray"
        
        # ユーザーが停止するまで待機
        Write-ColorOutput "待機中... (Ctrl+C で終了)" "Yellow"
        try {
            while ($true) {
                Start-Sleep -Seconds 5
                # プロセスが生きているかチェック
                if ($BackendJob.HasExited) {
                    Write-ColorOutput "⚠️ バックエンドプロセスが終了しました" "Red"
                }
                if ($FrontendJob.HasExited) {
                    Write-ColorOutput "⚠️ フロントエンドプロセスが終了しました" "Red"
                }
            }
        } catch [System.Management.Automation.PipelineStoppedException] {
            Write-ColorOutput "🛑 ユーザーによって中断されました" "Yellow"
        }
        
    } catch {
        Write-ColorOutput "❌ エラーが発生しました: $($_.Exception.Message)" "Red"
        Write-ColorOutput "📋 ログファイルを確認してください:" "Yellow"
        Write-ColorOutput "  $BackendErrorLogFile" "Gray"
        Write-ColorOutput "  $FrontendErrorLogFile" "Gray"
        exit 1
    }
}

# スクリプト実行
Main

@echo off
chcp 65001
rem WhatTimeNextTrain 簡易起動スクリプト (Windows)
rem 
rem このバッチファイルはバックエンドとフロントエンドを同時に起動します

title WhatTimeNextTrain Launcher

echo.
echo ======================================================
echo  🚃 WhatTimeNextTrain 起動中...
echo ======================================================
echo.

rem プロジェクトディレクトリの設定
set PROJECT_ROOT=%~dp0
set BACKEND_PATH=%PROJECT_ROOT%backend
set FRONTEND_PATH=%PROJECT_ROOT%frontend

rem ログディレクトリを作成
if not exist "%PROJECT_ROOT%logs" mkdir "%PROJECT_ROOT%logs"

echo 📁 プロジェクトディレクトリ: %PROJECT_ROOT%
echo 🐍 バックエンドパス: %BACKEND_PATH%
echo 🌐 フロントエンドパス: %FRONTEND_PATH%
echo.

rem バックエンドディレクトリの存在確認
if not exist "%BACKEND_PATH%" (
    echo ❌ バックエンドディレクトリが見つかりません: %BACKEND_PATH%
    pause
    exit /b 1
)

rem フロントエンドディレクトリの存在確認
if not exist "%FRONTEND_PATH%" (
    echo ❌ フロントエンドディレクトリが見つかりません: %FRONTEND_PATH%
    pause
    exit /b 1
)

echo 🚀 バックエンド (Python + Flask) を起動中...
cd /d "%BACKEND_PATH%"

rem Pythonの確認と起動
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Pythonが見つかりません。Pythonをインストールしてください。
    pause
    exit /b 1
)

rem バックエンドを新しいウィンドウで起動
start "WhatTimeNextTrain Backend" cmd /k "python run.py"

echo ✅ バックエンドを起動しました (http://localhost:5000)
echo.

echo ⏳ バックエンドの起動を待機中...
timeout /t 5 /nobreak >nul

echo 🚀 フロントエンド (Vue.js + Vite) を起動中...
cd /d "%FRONTEND_PATH%"

rem Node.jsの確認
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.jsが見つかりません。Node.jsをインストールしてください。
    echo 💾 ダウンロード: https://nodejs.org/
    pause
    exit /b 1
)

rem 依存関係の確認とインストール
if not exist "node_modules" (
    echo 📦 依存関係をインストール中...
    npm install
    if errorlevel 1 (
        echo ❌ npm install に失敗しました
        pause
        exit /b 1
    )
    echo ✅ 依存関係のインストールが完了しました
)

rem フロントエンドを新しいウィンドウで起動
start "WhatTimeNextTrain Frontend" cmd /k "npm run dev"

echo ✅ フロントエンドを起動しました (http://localhost:3000)
echo.

echo 🎉 全てのサービスが起動しました！
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 🌐 フロントエンド: http://localhost:3000
echo 🔧 バックエンドAPI: http://localhost:5000
echo 📋 ヘルスチェック: http://localhost:5000/api/health
echo.
echo 💡 各サービスは別ウィンドウで実行されています
echo 🛑 停止するには各ウィンドウで Ctrl+C を押してください
echo.

rem ブラウザを自動で開く（オプション）
echo 🌐 ブラウザでアプリケーションを開きますか？ (Y/N)
choice /c YN /t 10 /d Y /m "10秒後に自動でYesが選択されます"
if errorlevel 2 goto :skip_browser
if errorlevel 1 (
    echo 🚀 ブラウザを起動中...
    start http://localhost:3000
)

:skip_browser
echo.
echo ✨ セットアップ完了！アプリケーションをお楽しみください
pause

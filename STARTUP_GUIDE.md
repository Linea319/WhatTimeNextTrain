# 🚀 自動起動スクリプト使用方法

このプロジェクトには、Windows環境とLinux環境（Raspberry Pi）用の自動起動スクリプトが用意されています。

## 📁 ファイル構成

```
WhatTimeNextTrain/
├── start-services.ps1          # Windows PowerShell スクリプト（高機能版）
├── start-services.bat          # Windows バッチファイル（シンプル版）
├── start-services.sh           # Linux/Raspberry Pi Bash スクリプト
├── setup-raspberry-pi.sh       # Raspberry Pi 初期セットアップスクリプト
└── systemd/                    # systemd サービス設定（本番環境用）
    ├── README.md
    ├── whattimenexttrain-backend.service
    └── whattimenexttrain-frontend.service
```

## 🖥️ Windows環境での使用方法

### 方法1: PowerShellスクリプト（推奨）

**基本使用:**
```powershell
# サービス開始
.\start-services.ps1

# サービス停止
.\start-services.ps1 -StopServices

# サービス再起動
.\start-services.ps1 -RestartServices
```

**特徴:**
- ✅ カラフルな出力
- ✅ 詳細なエラーハンドリング
- ✅ 自動的なサーバー起動確認
- ✅ ログファイル管理
- ✅ プロセス監視

### 方法2: バッチファイル（シンプル）

```cmd
# ダブルクリックまたはコマンドプロンプトから実行
start-services.bat
```

**特徴:**
- ✅ シンプルで理解しやすい
- ✅ 別ウィンドウでサービス起動
- ✅ ブラウザ自動起動オプション
- ✅ 依存関係の自動インストール

## 🍓 Raspberry Pi (Linux) での使用方法

### 初回セットアップ

```bash
# セットアップスクリプトを実行
chmod +x setup-raspberry-pi.sh
./setup-raspberry-pi.sh
```

このスクリプトが行うこと:
- ✅ 必要なパッケージのインストール（Python3, Node.js）
- ✅ 仮想環境の作成と依存関係のインストール
- ✅ ディレクトリ権限の設定
- ✅ systemdサービスの設定（オプション）

### 開発環境での使用

```bash
# 実行権限を付与（初回のみ）
chmod +x start-services.sh

# サービス開始
./start-services.sh start

# サービス停止
./start-services.sh stop

# サービス再起動
./start-services.sh restart

# サービス状態確認
./start-services.sh status
```

**オプション:**
```bash
# ブラウザを自動で開く
./start-services.sh start --auto-browser

# フロントエンドのみ起動
./start-services.sh start --no-backend

# バックエンドのみ起動
./start-services.sh start --no-frontend
```

### 本番環境（systemdサービス）

systemdサービスとして設定した場合:

```bash
# サービス状態確認
sudo systemctl status whattimenexttrain-backend.service
sudo systemctl status whattimenexttrain-frontend.service

# サービス開始
sudo systemctl start whattimenexttrain-backend.service
sudo systemctl start whattimenexttrain-frontend.service

# サービス停止
sudo systemctl stop whattimenexttrain-backend.service
sudo systemctl stop whattimenexttrain-frontend.service

# 自動起動の有効化/無効化
sudo systemctl enable whattimenexttrain-backend.service
sudo systemctl disable whattimenexttrain-backend.service

# ログ確認
sudo journalctl -u whattimenexttrain-backend.service -f
sudo journalctl -u whattimenexttrain-frontend.service -f
```

## 🌐 アクセス先URL

起動完了後、以下のURLでアクセスできます:

- **フロントエンド（メインアプリ）**: http://localhost:3000
- **バックエンドAPI**: http://localhost:5000
- **APIヘルスチェック**: http://localhost:5000/api/health
- **LAN内からのアクセス**: http://[RaspberryPiのIP]:3000

## 📋 ログファイル

ログファイルは `logs/` ディレクトリに保存されます:

```
logs/
├── backend.log     # バックエンド（Python/Flask）のログ
└── frontend.log    # フロントエンド（Vue.js/Vite）のログ
```

## 🔧 トラブルシューティング

### よくある問題と解決方法

**1. Pythonが見つからない**
```bash
# Pythonをインストール
sudo apt install python3 python3-pip python3-venv  # Linux
# Windows: https://python.org からダウンロードしてインストール
```

**2. Node.jsが見つからない**
```bash
# Node.js LTSをインストール
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs  # Linux
# Windows: https://nodejs.org からダウンロードしてインストール
```

**3. ポートが既に使用されている**
```bash
# 使用中のポートを確認
sudo netstat -tlnp | grep :5000  # バックエンド
sudo netstat -tlnp | grep :3000  # フロントエンド

# プロセスを停止
sudo kill -9 [PID]
```

**4. 権限エラー (Linux)**
```bash
# スクリプトに実行権限を付与
chmod +x start-services.sh
chmod +x setup-raspberry-pi.sh
```

**5. 依存関係エラー**
```bash
# Python依存関係の再インストール
cd backend
pip install -r requirements.txt

# Node.js依存関係の再インストール
cd frontend
rm -rf node_modules package-lock.json
npm install
```

## 🎯 使用例

### 開発時の典型的なワークフロー

**Windows:**
```powershell
# 開発開始
.\start-services.ps1

# 開発終了
.\start-services.ps1 -StopServices
```

**Linux/Raspberry Pi:**
```bash
# 開発開始
./start-services.sh start

# 状態確認
./start-services.sh status

# 開発終了
./start-services.sh stop
```

### 本番環境での運用（Raspberry Pi）

```bash
# 初回セットアップ
./setup-raspberry-pi.sh

# システム再起動後の状態確認
sudo systemctl status whattimenexttrain-*

# 設定変更後のサービス再起動
sudo systemctl restart whattimenexttrain-backend.service
sudo systemctl restart whattimenexttrain-frontend.service
```

## 💡 ヒント

- **Raspberry Pi**: LAN内の他のデバイスからアクセスする場合は、Raspberry PiのIPアドレスを使用してください
- **ファイアウォール**: 必要に応じてポート3000と5000を開放してください
- **自動起動**: systemdサービスを使用すると、Raspberry Pi起動時に自動でアプリケーションが開始されます
- **設定変更**: `backend/config.py` で移動時間などの設定を変更できます
- **時刻表更新**: `backend/data/train_schedule.json` で列車時刻表を更新できます

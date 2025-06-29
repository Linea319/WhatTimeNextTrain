#!/bin/bash

# WhatTimeNextTrain Raspberry Pi セットアップスクリプト
# 
# このスクリプトは必要な依存関係をインストールし、
# systemdサービスとして自動起動設定を行います

set -e

print_color() {
    local color_code=$1
    local message=$2
    echo -e "\e[${color_code}m${message}\e[0m"
}

print_info() {
    print_color "36" "$1"
}

print_success() {
    print_color "32" "$1"
}

print_warning() {
    print_color "33" "$1"
}

print_error() {
    print_color "31" "$1"
}

print_header() {
    print_color "35" "$1"
}

# 現在のユーザーとディレクトリを取得
CURRENT_USER=$(whoami)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

print_header "🚃 WhatTimeNextTrain Raspberry Pi セットアップ"
print_header "=============================================="
echo ""

print_info "現在のユーザー: $CURRENT_USER"
print_info "プロジェクトディレクトリ: $PROJECT_DIR"
echo ""

# root権限チェック
if [ "$EUID" -eq 0 ]; then
    print_error "❌ rootユーザーでは実行しないでください"
    print_error "   通常ユーザーで実行し、必要に応じてsudoを使用します"
    exit 1
fi

# システム更新
print_info "📦 システムパッケージを更新中..."
sudo apt update && sudo apt upgrade -y

# Python3とpipのインストール
print_info "🐍 Python3環境をセットアップ中..."
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Node.jsのインストール（NodeSourceから最新LTS版）
if ! command -v node >/dev/null 2>&1; then
    print_info "📱 Node.js LTSをインストール中..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    print_success "✅ Node.js は既にインストール済み: $(node --version)"
fi

# バックエンド依存関係のセットアップ
print_info "🐍 バックエンド Python環境をセットアップ中..."
cd "$PROJECT_DIR/backend"

# 仮想環境の作成
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_success "✅ Python仮想環境を作成しました"
fi

# 仮想環境をアクティベートして依存関係をインストール
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

print_success "✅ バックエンド依存関係のインストール完了"

# フロントエンド依存関係のセットアップ
print_info "📱 フロントエンド Node.js環境をセットアップ中..."
cd "$PROJECT_DIR/frontend"

# npm依存関係のインストール
npm install
print_success "✅ フロントエンド依存関係のインストール完了"

# ログディレクトリの作成
cd "$PROJECT_DIR"
mkdir -p logs pids
print_success "✅ ログディレクトリを作成しました"

# 実行権限の設定
chmod +x start-services.sh
print_success "✅ 起動スクリプトに実行権限を設定しました"

# systemdサービスのインストール（オプション）
echo ""
print_warning "🔧 systemdサービスとして自動起動を設定しますか？"
print_info "   これにより、Raspberry Pi起動時に自動でアプリケーションが開始されます"
read -p "systemdサービスを設定しますか？ (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # サービスファイルのパスを更新
    print_info "🔧 systemdサービスファイルを設定中..."
    
    # テンプレートからサービスファイルを作成
    sudo mkdir -p /etc/systemd/system
    
    # バックエンドサービス
    sudo tee /etc/systemd/system/whattimenexttrain-backend.service > /dev/null <<EOF
[Unit]
Description=WhatTimeNextTrain Backend API Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$PROJECT_DIR/backend
Environment=PYTHONPATH=$PROJECT_DIR/backend
Environment=FLASK_ENV=production
ExecStartPre=/bin/sleep 10
ExecStart=$PROJECT_DIR/backend/venv/bin/python run.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # フロントエンドサービス
    sudo tee /etc/systemd/system/whattimenexttrain-frontend.service > /dev/null <<EOF
[Unit]
Description=WhatTimeNextTrain Frontend Web Server
After=network.target whattimenexttrain-backend.service
Wants=network.target
Requires=whattimenexttrain-backend.service

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$PROJECT_DIR/frontend
Environment=NODE_ENV=production
ExecStartPre=/bin/sleep 15
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # systemdの再読み込みとサービス有効化
    sudo systemctl daemon-reload
    sudo systemctl enable whattimenexttrain-backend.service
    sudo systemctl enable whattimenexttrain-frontend.service
    
    print_success "✅ systemdサービスを設定しました"
    
    echo ""
    print_warning "サービスを今すぐ開始しますか？"
    read -p "サービスを開始しますか？ (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl start whattimenexttrain-backend.service
        sudo systemctl start whattimenexttrain-frontend.service
        
        sleep 5
        
        print_info "📊 サービス状態:"
        sudo systemctl status whattimenexttrain-backend.service --no-pager -l
        echo ""
        sudo systemctl status whattimenexttrain-frontend.service --no-pager -l
    fi
    
    echo ""
    print_info "🔧 systemd サービス管理コマンド:"
    print_info "  状態確認: sudo systemctl status whattimenexttrain-backend.service"
    print_info "  開始:     sudo systemctl start whattimenexttrain-backend.service"
    print_info "  停止:     sudo systemctl stop whattimenexttrain-backend.service"
    print_info "  再起動:   sudo systemctl restart whattimenexttrain-backend.service"
    print_info "  ログ確認: sudo journalctl -u whattimenexttrain-backend.service -f"
    
else
    print_info "systemdサービスの設定をスキップしました"
    print_info "手動起動は以下のコマンドで行えます:"
    print_info "  ./start-services.sh start"
fi

echo ""
print_success "🎉 セットアップが完了しました！"
print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# IPアドレスを表示
LOCAL_IP=$(hostname -I | awk '{print $1}')
print_info "📡 ローカルIPアドレス: $LOCAL_IP"
print_info ""
print_info "🌐 アクセス先URL:"
print_info "  ローカル:     http://localhost:3000"
print_info "  LAN内から:   http://$LOCAL_IP:3000"
print_info "  API:        http://$LOCAL_IP:5000"
print_info ""

if ! sudo systemctl is-enabled whattimenexttrain-backend.service >/dev/null 2>&1; then
    print_info "🚀 手動起動コマンド:"
    print_info "  ./start-services.sh start      # サービス開始"
    print_info "  ./start-services.sh stop       # サービス停止"
    print_info "  ./start-services.sh restart    # サービス再起動"
    print_info "  ./start-services.sh status     # サービス状態確認"
fi

echo ""
print_warning "💡 ヒント:"
print_warning "  - 列車時刻表は backend/data/train_schedule.json で編集できます"
print_warning "  - 移動時間の設定は backend/config.py で変更できます"
print_warning "  - ログファイルは logs/ ディレクトリに保存されます"

echo ""
print_success "✨ WhatTimeNextTrain のセットアップが完了しました！"

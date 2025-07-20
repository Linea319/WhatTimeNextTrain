#!/bin/bash

# WhatTimeNextTrain Termux セットアップスクリプト
# 
# このスクリプトはTermux環境で必要な依存関係をインストールし、
# アプリケーションをセットアップします
# 
# 注意: Termuxではsudoコマンドやsystemdは使用できません

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

print_header "🚃 WhatTimeNextTrain Termux セットアップ"
print_header "========================================"
echo ""

print_info "現在のユーザー: $CURRENT_USER"
print_info "プロジェクトディレクトリ: $PROJECT_DIR"
echo ""

# Termux環境チェック
if [ -z "$PREFIX" ]; then
    print_warning "⚠️  Termux環境ではない可能性があります"
    print_warning "   このスクリプトはTermux専用です"
    echo ""
fi

# パッケージリストの更新
print_info "📦 パッケージリストを更新中..."
pkg update -y

# 必要なパッケージのインストール
print_info "📦 必要なパッケージをインストール中..."
pkg install -y curl wget git

# Python3のインストール
print_info "🐍 Python3環境をセットアップ中..."
pkg install -y python python-pip

# Node.jsのインストール
if ! command -v node >/dev/null 2>&1; then
    print_info "📱 Node.jsをインストール中..."
    pkg install -y nodejs npm
else
    print_success "✅ Node.js は既にインストール済み: $(node --version)"
fi

# gitのインストール（クローンが必要な場合）
if ! command -v git >/dev/null 2>&1; then
    print_info "📥 Gitをインストール中..."
    pkg install -y git
else
    print_success "✅ Git は既にインストール済み: $(git --version)"
fi

# バックエンド依存関係のセットアップ
print_info "🐍 バックエンド Python環境をセットアップ中..."
cd "$PROJECT_DIR/backend"

# 仮想環境の作成（Termuxでも仮想環境は使用可能）
if [ ! -d "venv" ]; then
    python -m venv venv
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
if [ -f "start-termux.sh" ]; then
    chmod +x start-termux.sh
    print_success "✅ 起動スクリプトに実行権限を設定しました"
else
    print_warning "⚠️  start-termux.sh が見つかりません"
    print_info "   高機能なTermux用起動スクリプトを使用する場合は、"
    print_info "   別途 start-termux.sh ファイルを配置してください"
fi

# Termux自動起動設定スクリプトの作成
print_info "🔧 Termux自動起動設定スクリプトを作成中..."

cat > setup-termux-autostart.sh << 'EOF'
#!/bin/bash

# Termux自動起動設定スクリプト
# 
# Termuxアプリが起動時に自動でWhatTimeNextTrainを開始するための設定

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERMUX_HOME="$HOME"

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

print_info "🔧 Termux自動起動設定を作成中..."

# .bashrcに自動起動コマンドを追加
if ! grep -q "WhatTimeNextTrain" "$TERMUX_HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$TERMUX_HOME/.bashrc"
    echo "# WhatTimeNextTrain 自動起動設定" >> "$TERMUX_HOME/.bashrc"
    echo "echo '🚃 WhatTimeNextTrainを自動起動しますか？'" >> "$TERMUX_HOME/.bashrc"
    echo "echo '  y: 起動  n: スキップ  s: 状態確認'" >> "$TERMUX_HOME/.bashrc"
    echo "read -p '選択してください (y/n/s): ' -n 1 -r" >> "$TERMUX_HOME/.bashrc"
    echo "echo" >> "$TERMUX_HOME/.bashrc"
    echo "case \$REPLY in" >> "$TERMUX_HOME/.bashrc"
    echo "    [Yy]*)" >> "$TERMUX_HOME/.bashrc"
    echo "        cd \"$SCRIPT_DIR\" && ./start-termux.sh start" >> "$TERMUX_HOME/.bashrc"
    echo "        ;;" >> "$TERMUX_HOME/.bashrc"
    echo "    [Ss]*)" >> "$TERMUX_HOME/.bashrc"
    echo "        cd \"$SCRIPT_DIR\" && ./start-termux.sh status" >> "$TERMUX_HOME/.bashrc"
    echo "        ;;" >> "$TERMUX_HOME/.bashrc"
    echo "    *)" >> "$TERMUX_HOME/.bashrc"
    echo "        echo '⏭️  自動起動をスキップしました'" >> "$TERMUX_HOME/.bashrc"
    echo "        echo '手動起動: cd $SCRIPT_DIR && ./start-termux.sh start'" >> "$TERMUX_HOME/.bashrc"
    echo "        ;;" >> "$TERMUX_HOME/.bashrc"
    echo "esac" >> "$TERMUX_HOME/.bashrc"
    
    print_success "✅ .bashrcに自動起動設定を追加しました"
else
    print_warning "⚠️  .bashrcに既に自動起動設定が存在します"
fi

print_info ""
print_info "📝 設定完了！"
print_info "   次回Termux起動時に自動起動プロンプトが表示されます"
print_info ""
print_info "🔧 自動起動設定を削除するには:"
print_info "   nano ~/.bashrc でファイルを編集し、WhatTimeNextTrain関連の行を削除してください"
EOF

chmod +x setup-termux-autostart.sh
print_success "✅ Termux自動起動設定スクリプトを作成しました"

echo ""
print_success "🎉 Termuxセットアップが完了しました！"
print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ローカルIPアドレスを表示（Termuxでも取得可能）
if command -v hostname >/dev/null 2>&1; then
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "取得できませんでした")
    if [ "$LOCAL_IP" != "取得できませんでした" ]; then
        print_info "📡 ローカルIPアドレス: $LOCAL_IP"
    fi
fi

print_info ""
print_info "🌐 アクセス先URL:"
print_info "  ローカル:     http://localhost:3000"
if [ "$LOCAL_IP" != "取得できませんでした" ] && [ -n "$LOCAL_IP" ]; then
    print_info "  LAN内から:   http://$LOCAL_IP:3000"
    print_info "  API:        http://$LOCAL_IP:5000"
fi
print_info ""

print_info "🚀 Termux起動コマンド:"
if [ -f "start-termux.sh" ]; then
    print_info "  ./start-termux.sh start      # サービス開始"
    print_info "  ./start-termux.sh stop       # サービス停止"
    print_info "  ./start-termux.sh restart    # サービス再起動"
    print_info "  ./start-termux.sh status     # サービス状態確認"
    print_info "  ./start-termux.sh logs backend   # バックエンドログ確認"
    print_info "  ./start-termux.sh logs frontend  # フロントエンドログ確認"
    print_info "  ./start-termux.sh wakelock on     # Wakelock有効化"
    print_info "  ./start-termux.sh help            # 詳細なヘルプ表示"
else
    print_info "  ./start-services.sh start   # サービス開始（基本版）"
    print_info "  ./start-services.sh stop    # サービス停止（基本版）"
    print_warning "   高機能版を使用するには start-termux.sh を配置してください"
fi

echo ""
print_warning "🔧 自動起動設定（オプション）:"
print_warning "  ./setup-termux-autostart.sh   # Termux起動時の自動起動設定"

echo ""
print_warning "💡 Termux使用時のヒント:"
print_warning "  - Termuxではバックグラウンド実行に制限があります"
print_warning "  - アプリを継続実行するにはTermuxを開いたままにしてください"
print_warning "  - Termux:Wakelock アプリを使用すると安定性が向上します"
print_warning "  - 列車時刻表は backend/data/ ディレクトリで編集できます"
print_warning "  - 移動時間の設定は backend/config.py で変更できます"

echo ""
print_success "✨ WhatTimeNextTrain のTermuxセットアップが完了しました！"
print_info ""
print_info "🔥 今すぐ起動するには:"
if [ -f "start-termux.sh" ]; then
    print_info "   ./start-termux.sh start"
    print_info ""
    print_info "💡 高機能版の特徴:"
    print_info "   - Wakelock制御機能"
    print_info "   - 詳細なプロセス監視"
    print_info "   - リアルタイムログ表示"
    print_info "   - エラーハンドリング強化"
else
    print_info "   ./start-services.sh start"
fi

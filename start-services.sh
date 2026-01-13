#!/bin/bash

# WhatTimeNextTrain 開発環境起動スクリプト (Linux/Raspberry Pi)
# 
# このスクリプトはバックエンドとフロントエンドを同時に起動します

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BACKEND_PATH="$PROJECT_ROOT/backend"
FRONTEND_PATH="$PROJECT_ROOT/frontend"
LOG_DIR="$PROJECT_ROOT/logs"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
PID_DIR="$PROJECT_ROOT/pids"
BACKEND_PID="$PID_DIR/backend.pid"
FRONTEND_PID="$PID_DIR/frontend.pid"

# 色付きテキスト関数
print_color() {
    local color_code=$1
    local message=$2
    echo -e "\e[${color_code}m${message}\e[0m"
}

print_info() {
    print_color "36" "$1"  # Cyan
}

print_success() {
    print_color "32" "$1"  # Green
}

print_warning() {
    print_color "33" "$1"  # Yellow
}

print_error() {
    print_color "31" "$1"  # Red
}

print_header() {
    print_color "35" "$1"  # Magenta
}

# ログとPIDディレクトリを作成
create_directories() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
}

# 使用方法を表示
show_usage() {
    echo "使用方法: $0 [start|stop|restart|status]"
    echo ""
    echo "コマンド:"
    echo "  start   - サービスを起動"
    echo "  stop    - サービスを停止"
    echo "  restart - サービスを再起動"
    echo "  status  - サービスの状態を確認"
    echo ""
    echo "オプション:"
    echo "  --auto-browser  - 起動後にブラウザを自動で開く"
    echo "  --no-frontend   - フロントエンドを起動しない"
    echo "  --no-backend    - バックエンドを起動しない"
}

# プロセスIDを確認
check_pid() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "$pid"
            return 0
        else
            rm -f "$pid_file"
            return 1
        fi
    fi
    return 1
}

# サービス停止
stop_services() {
    print_warning "🛑 サービスを停止中..."
    
    local stopped=false
    
    # バックエンドを停止
    if backend_pid=$(check_pid "$BACKEND_PID"); then
        print_info "バックエンドプロセス (PID: $backend_pid) を停止中..."
        kill "$backend_pid" 2>/dev/null || true
        sleep 2
        if ps -p "$backend_pid" > /dev/null 2>&1; then
            print_warning "強制終了中..."
            kill -9 "$backend_pid" 2>/dev/null || true
        fi
        rm -f "$BACKEND_PID"
        print_success "✅ バックエンドを停止しました"
        stopped=true
    fi
    
    # フロントエンドを停止
    if frontend_pid=$(check_pid "$FRONTEND_PID"); then
        print_info "フロントエンドプロセス (PID: $frontend_pid) を停止中..."
        kill "$frontend_pid" 2>/dev/null || true
        sleep 2
        if ps -p "$frontend_pid" > /dev/null 2>&1; then
            print_warning "強制終了中..."
            kill -9 "$frontend_pid" 2>/dev/null || true
        fi
        rm -f "$FRONTEND_PID"
        print_success "✅ フロントエンドを停止しました"
        stopped=true
    fi
    
    if [ "$stopped" = true ]; then
        print_success "🏁 全てのサービスが停止されました"
    else
        print_info "ℹ️ 実行中のサービスはありませんでした"
    fi
}

# サービス状態確認
check_status() {
    print_header "📊 サービス状態確認"
    print_header "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "=" "="
    
    local backend_status="❌ 停止中"
    local frontend_status="❌ 停止中"
    
    # バックエンド状態確認
    if backend_pid=$(check_pid "$BACKEND_PID"); then
        backend_status="✅ 実行中 (PID: $backend_pid)"
        
        # ヘルスチェック
        if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
            backend_status="$backend_status - API応答正常"
        else
            backend_status="$backend_status - API応答なし"
        fi
    fi
    
    # フロントエンド状態確認
    if frontend_pid=$(check_pid "$FRONTEND_PID"); then
        frontend_status="✅ 実行中 (PID: $frontend_pid)"
        
        # ヘルスチェック
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            frontend_status="$frontend_status - Web応答正常"
        else
            frontend_status="$frontend_status - Web応答なし"
        fi
    fi
    
    print_info "🐍 バックエンド:  $backend_status"
    print_info "🌐 フロントエンド: $frontend_status"
    echo ""
    
    if [[ "$backend_status" == *"実行中"* ]] || [[ "$frontend_status" == *"実行中"* ]]; then
        print_info "🔗 アクセス先:"
        if [[ "$frontend_status" == *"実行中"* ]]; then
            print_info "  フロントエンド: http://localhost:3000"
        fi
        if [[ "$backend_status" == *"実行中"* ]]; then
            print_info "  バックエンドAPI: http://localhost:5000"
            print_info "  ヘルスチェック: http://localhost:5000/api/health"
        fi
        echo ""
        
        print_info "📁 ログファイル:"
        print_info "  Backend:  $BACKEND_LOG"
        print_info "  Frontend: $FRONTEND_LOG"
    fi
}

# バックエンドを起動
start_backend() {
    if [ "$NO_BACKEND" = true ]; then
        return 0
    fi
    
    print_info "🚀 バックエンド (Python + Flask) を起動中..."
    
    # ディレクトリ確認
    if [ ! -d "$BACKEND_PATH" ]; then
        print_error "❌ バックエンドディレクトリが見つかりません: $BACKEND_PATH"
        return 1
    fi
    
    # uvが利用可能か確認
    if ! command -v uv >/dev/null 2>&1; then
        print_error "❌ uvが見つかりません。以下からインストールしてください:"
        print_error "   https://docs.astral.sh/uv/getting-started/installation/"
        return 1
    fi
    print_success "✅ uv found: $(uv --version)"
    
    # 仮想環境の作成（存在しない場合のみ）
    if [ ! -d "$BACKEND_PATH/venv" ]; then
        print_info "📦 仮想環境を作成中..."
        cd "$BACKEND_PATH"
        uv venv venv
        if [ $? -ne 0 ]; then
            print_error "❌ 仮想環境の作成に失敗しました"
            return 1
        fi
        print_success "✅ 仮想環境を作成しました"
    fi
    
    # 仮想環境のアクティベートと依存関係のインストール
    print_info "📦 依存関係をインストール中..."
    cd "$BACKEND_PATH"
    source venv/bin/activate
    uv pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        print_error "❌ 依存関係のインストール失敗"
        return 1
    fi
    deactivate
    print_success "✅ 依存関係をインストールしました"
    
    # バックエンドを起動（仮想環境内で実行）
    cd "$BACKEND_PATH"
    nohup venv/bin/python run.py > "$BACKEND_LOG" 2>&1 &
    echo $! > "$BACKEND_PID"
    cd "$PROJECT_ROOT"
    
    # 起動確認
    print_info "⏳ バックエンドサーバーの起動を待機中..."
    for i in {1..30}; do
        sleep 1
        if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
            print_success "✅ バックエンドサーバーが起動しました (http://localhost:5000)"
            return 0
        fi
    done
    
    print_error "❌ バックエンドサーバーの起動に失敗しました"
    return 1
}

# フロントエンドを起動
start_frontend() {
    if [ "$NO_FRONTEND" = true ]; then
        return 0
    fi
    
    print_info "🚀 フロントエンド (Vue.js + Vite) を起動中..."
    
    # ディレクトリ確認
    if [ ! -d "$FRONTEND_PATH" ]; then
        print_error "❌ フロントエンドディレクトリが見つかりません: $FRONTEND_PATH"
        return 1
    fi
    
    # Node.jsの確認
    if ! command -v node >/dev/null 2>&1; then
        print_error "❌ Node.jsが見つかりません。Node.jsをインストールしてください。"
        print_error "💾 インストール: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
        return 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        print_error "❌ npmが見つかりません。"
        return 1
    fi
    
    print_success "✅ Node.js found: $(node --version)"
    print_success "✅ npm found: $(npm --version)"
    
    # package.jsonの確認
    if [ ! -f "$FRONTEND_PATH/package.json" ]; then
        print_error "❌ package.jsonが見つかりません: $FRONTEND_PATH/package.json"
        return 1
    fi
    
    # 依存関係のインストール
    if [ ! -d "$FRONTEND_PATH/node_modules" ]; then
        print_info "📦 依存関係をインストール中..."
        cd "$FRONTEND_PATH"
        npm install
        cd "$PROJECT_ROOT"
        print_success "✅ 依存関係のインストールが完了しました"
    fi
    
    # フロントエンドを起動
    cd "$FRONTEND_PATH"
    nohup npm run dev > "$FRONTEND_LOG" 2>&1 &
    echo $! > "$FRONTEND_PID"
    cd "$PROJECT_ROOT"
    
    # 起動確認
    print_info "⏳ フロントエンドサーバーの起動を待機中..."
    for i in {1..30}; do
        sleep 2
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            print_success "✅ フロントエンドサーバーが起動しました (http://localhost:3000)"
            return 0
        fi
    done
    
    print_warning "⚠️ フロントエンドサーバーの確認に失敗しましたが、起動は継続します"
    return 0
}

# サービス起動
start_services() {
    print_header "🚃 WhatTimeNextTrain 起動スクリプト (Linux/Raspberry Pi)"
    print_header "==============================================="
    
    # 既に実行中かチェック
    if check_pid "$BACKEND_PID" >/dev/null || check_pid "$FRONTEND_PID" >/dev/null; then
        print_warning "⚠️ 一部のサービスが既に実行中です"
        check_status
        read -p "続行しますか？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "処理を中断しました"
            exit 0
        fi
    fi
    
    # バックエンド起動
    if ! start_backend; then
        print_error "バックエンドの起動に失敗しました"
        return 1
    fi
    
    sleep 3
    
    # フロントエンド起動
    if ! start_frontend; then
        print_error "フロントエンドの起動に失敗しました"
        return 1
    fi
    
    echo ""
    print_success "🎉 全てのサービスが起動しました！"
    print_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "🌐 フロントエンド: http://localhost:3000"
    print_info "🔧 バックエンドAPI: http://localhost:5000"
    print_info "📋 ヘルスチェック: http://localhost:5000/api/health"
    echo ""
    print_info "📁 ログファイル:"
    print_info "  Backend:  $BACKEND_LOG"
    print_info "  Frontend: $FRONTEND_LOG"
    echo ""
    print_warning "⏹️  サービス停止: $0 stop"
    print_warning "🔄 サービス再起動: $0 restart"
    print_warning "📊 サービス状態確認: $0 status"
    
    # ブラウザを自動で開く（Raspberry Piでデスクトップ環境がある場合）
    if [ "$AUTO_BROWSER" = true ] && command -v xdg-open >/dev/null 2>&1; then
        print_info "🚀 ブラウザを起動中..."
        #xdg-open http://localhost:3000 &
        chromium-browser --start-fullscreen http://localhost:3000 &
    fi
}

# メイン処理
main() {
    create_directories
    
    # コマンドライン引数を解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-browser)
                AUTO_BROWSER=true
                shift
                ;;
            --no-frontend)
                NO_FRONTEND=true
                shift
                ;;
            --no-backend)
                NO_BACKEND=true
                shift
                ;;
            start|stop|restart|status)
                COMMAND=$1
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "未知のオプション: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # デフォルトコマンドは start
    if [ -z "$COMMAND" ]; then
        COMMAND="start"
    fi
    
    case $COMMAND in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            stop_services
            sleep 2
            start_services
            ;;
        status)
            check_status
            ;;
        *)
            print_error "未知のコマンド: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"

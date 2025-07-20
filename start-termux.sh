#!/bin/bash

# WhatTimeNextTrain Termux専用起動スクリプト
# 
# Termux環境での安定したバックグラウンド実行を提供します
# Wakelock サポートやプロセス監視機能を含みます

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
LOGS_DIR="$PROJECT_DIR/logs"
PIDS_DIR="$PROJECT_DIR/pids"

# ログとPIDディレクトリの作成
mkdir -p "$LOGS_DIR" "$PIDS_DIR"

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

# Wakelock制御関数
enable_wakelock() {
    if command -v termux-wake-lock >/dev/null 2>&1; then
        termux-wake-lock
        print_success "🔋 Wakelockを有効化しました"
        echo "enabled" > "$PIDS_DIR/wakelock.status"
        return 0
    else
        print_warning "⚠️  termux-wake-lock コマンドが見つかりません"
        print_warning "   Termux:API アプリをインストールしてください"
        return 1
    fi
}

disable_wakelock() {
    if command -v termux-wake-unlock >/dev/null 2>&1; then
        termux-wake-unlock
        print_success "🔋 Wakelockを無効化しました"
        rm -f "$PIDS_DIR/wakelock.status"
        return 0
    else
        print_warning "⚠️  termux-wake-unlock コマンドが見つかりません"
        return 1
    fi
}

check_wakelock_status() {
    if [ -f "$PIDS_DIR/wakelock.status" ]; then
        print_success "  Wakelock: 有効"
    else
        print_error "  Wakelock: 無効"
    fi
}

# プロセス監視関数
is_process_running() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$pid_file"
            return 1
        fi
    else
        return 1
    fi
}

wait_for_service() {
    local service_name=$1
    local pid_file="$PIDS_DIR/${service_name}.pid"
    local max_wait=30
    local wait_time=0
    
    print_info "⏳ ${service_name}の起動を待機中..."
    
    while [ $wait_time -lt $max_wait ]; do
        if is_process_running "$pid_file"; then
            print_success "✅ ${service_name}が正常に起動しました"
            return 0
        fi
        sleep 1
        wait_time=$((wait_time + 1))
        printf "."
    done
    
    echo ""
    print_error "❌ ${service_name}の起動がタイムアウトしました"
    return 1
}

start_backend() {
    if is_process_running "$PIDS_DIR/backend.pid"; then
        print_warning "⚠️  バックエンドは既に実行中です"
        return 0
    fi
    
    print_info "🐍 バックエンドを起動中..."
    
    # バックエンドディレクトリの存在確認
    if [ ! -d "$BACKEND_DIR" ]; then
        print_error "❌ バックエンドディレクトリが見つかりません: $BACKEND_DIR"
        return 1
    fi
    
    # 仮想環境の存在確認
    if [ ! -f "$BACKEND_DIR/venv/bin/activate" ]; then
        print_error "❌ Python仮想環境が見つかりません"
        print_error "   先に setup-termux.sh を実行してください"
        return 1
    fi
    
    cd "$BACKEND_DIR"
    source venv/bin/activate
    
    # run.pyの存在確認
    if [ ! -f "run.py" ]; then
        print_error "❌ run.py が見つかりません"
        return 1
    fi
    
    # バックグラウンドで実行
    nohup python run.py > "$LOGS_DIR/backend.log" 2>&1 &
    local backend_pid=$!
    echo $backend_pid > "$PIDS_DIR/backend.pid"
    
    print_success "✅ バックエンドが起動しました (PID: $backend_pid)"
    
    # 起動確認
    if ! wait_for_service "backend"; then
        return 1
    fi
    
    return 0
}

start_frontend() {
    if is_process_running "$PIDS_DIR/frontend.pid"; then
        print_warning "⚠️  フロントエンドは既に実行中です"
        return 0
    fi
    
    print_info "📱 フロントエンドを起動中..."
    
    # フロントエンドディレクトリの存在確認
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "❌ フロントエンドディレクトリが見つかりません: $FRONTEND_DIR"
        return 1
    fi
    
    cd "$FRONTEND_DIR"
    
    # package.jsonの存在確認
    if [ ! -f "package.json" ]; then
        print_error "❌ package.json が見つかりません"
        return 1
    fi
    
    # node_modulesの存在確認
    if [ ! -d "node_modules" ]; then
        print_error "❌ node_modules が見つかりません"
        print_error "   先に npm install を実行してください"
        return 1
    fi
    
    # バックグラウンドで実行
    nohup npm run dev > "$LOGS_DIR/frontend.log" 2>&1 &
    local frontend_pid=$!
    echo $frontend_pid > "$PIDS_DIR/frontend.pid"
    
    print_success "✅ フロントエンドが起動しました (PID: $frontend_pid)"
    
    # 起動確認
    if ! wait_for_service "frontend"; then
        return 1
    fi
    
    return 0
}

stop_service() {
    local service_name=$1
    local pid_file="$PIDS_DIR/${service_name}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_info "🛑 ${service_name}を停止中..."
            
            # 優しく終了を試行
            kill "$pid"
            
            # 最大10秒待機
            local wait_time=0
            while [ $wait_time -lt 10 ] && kill -0 "$pid" 2>/dev/null; do
                sleep 1
                wait_time=$((wait_time + 1))
            done
            
            # まだ実行中なら強制終了
            if kill -0 "$pid" 2>/dev/null; then
                print_warning "⚠️  優しい終了が失敗しました。強制終了します..."
                kill -9 "$pid" 2>/dev/null || true
            fi
            
            rm -f "$pid_file"
            print_success "✅ ${service_name}を停止しました"
        else
            print_warning "⚠️  ${service_name}は既に停止しています"
            rm -f "$pid_file"
        fi
    else
        print_warning "⚠️  ${service_name}のPIDファイルが見つかりません"
    fi
}

show_status() {
    print_header "📊 WhatTimeNextTrain サービス状態"
    print_header "=================================="
    
    # システム情報
    print_info "🖥️  システム情報:"
    print_info "  Termux: $(uname -o 2>/dev/null || echo '不明')"
    print_info "  Python: $(python --version 2>/dev/null | cut -d' ' -f2 || echo '未インストール')"
    print_info "  Node.js: $(node --version 2>/dev/null || echo '未インストール')"
    echo ""
    
    # Wakelock状態
    print_info "🔋 電源管理:"
    check_wakelock_status
    echo ""
    
    # サービス状態
    print_info "🚀 サービス状態:"
    
    # バックエンド状態確認
    if is_process_running "$PIDS_DIR/backend.pid"; then
        local backend_pid=$(cat "$PIDS_DIR/backend.pid")
        print_success "  バックエンド: 実行中 (PID: $backend_pid)"
        
        # ポート確認
        if command -v ss >/dev/null 2>&1; then
            if ss -ltn | grep -q ":5000"; then
                print_success "    - API サーバー: http://localhost:5000 で待機中"
            else
                print_warning "    - ポート5000で待機していません"
            fi
        fi
    else
        print_error "  バックエンド: 停止中"
    fi
    
    # フロントエンド状態確認
    if is_process_running "$PIDS_DIR/frontend.pid"; then
        local frontend_pid=$(cat "$PIDS_DIR/frontend.pid")
        print_success "  フロントエンド: 実行中 (PID: $frontend_pid)"
        
        # ポート確認
        if command -v ss >/dev/null 2>&1; then
            if ss -ltn | grep -q ":3000"; then
                print_success "    - Webサーバー: http://localhost:3000 で待機中"
            else
                print_warning "    - ポート3000で待機していません"
            fi
        fi
    else
        print_error "  フロントエンド: 停止中"
    fi
    
    echo ""
    
    # ログファイル情報
    print_info "📋 ログファイル:"
    if [ -f "$LOGS_DIR/backend.log" ]; then
        local backend_log_size=$(wc -l < "$LOGS_DIR/backend.log" 2>/dev/null || echo "0")
        print_info "  バックエンド: $backend_log_size 行 ($LOGS_DIR/backend.log)"
    else
        print_info "  バックエンド: ログファイルなし"
    fi
    
    if [ -f "$LOGS_DIR/frontend.log" ]; then
        local frontend_log_size=$(wc -l < "$LOGS_DIR/frontend.log" 2>/dev/null || echo "0")
        print_info "  フロントエンド: $frontend_log_size 行 ($LOGS_DIR/frontend.log)"
    else
        print_info "  フロントエンド: ログファイルなし"
    fi
}

show_logs() {
    local service=$1
    local lines=${2:-50}
    
    case "$service" in
        backend)
            if [ -f "$LOGS_DIR/backend.log" ]; then
                print_info "📋 バックエンドログ (最新 $lines 行):"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                tail -n "$lines" "$LOGS_DIR/backend.log"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                print_info "リアルタイム表示: ./start-termux.sh logs backend follow"
            else
                print_error "❌ バックエンドログファイルが見つかりません"
            fi
            ;;
        frontend)
            if [ -f "$LOGS_DIR/frontend.log" ]; then
                print_info "📋 フロントエンドログ (最新 $lines 行):"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                tail -n "$lines" "$LOGS_DIR/frontend.log"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                print_info "リアルタイム表示: ./start-termux.sh logs frontend follow"
            else
                print_error "❌ フロントエンドログファイルが見つかりません"
            fi
            ;;
        follow)
            # 前の引数がbackendかfrontendかを確認
            echo "リアルタイムログ表示を開始します (Ctrl+C で終了)"
            ;;
        *)
            print_error "使用方法: $0 logs [backend|frontend] [lines]"
            print_info "  backend  - バックエンドログを表示"
            print_info "  frontend - フロントエンドログを表示"
            print_info "  lines    - 表示する行数 (デフォルト: 50)"
            print_info ""
            print_info "例:"
            print_info "  $0 logs backend        # バックエンドログの最新50行"
            print_info "  $0 logs frontend 100   # フロントエンドログの最新100行"
            ;;
    esac
}

follow_logs() {
    local service=$1
    
    case "$service" in
        backend)
            if [ -f "$LOGS_DIR/backend.log" ]; then
                print_info "📋 バックエンドログをリアルタイム表示中... (Ctrl+C で終了)"
                tail -f "$LOGS_DIR/backend.log"
            else
                print_error "❌ バックエンドログファイルが見つかりません"
            fi
            ;;
        frontend)
            if [ -f "$LOGS_DIR/frontend.log" ]; then
                print_info "📋 フロントエンドログをリアルタイム表示中... (Ctrl+C で終了)"
                tail -f "$LOGS_DIR/frontend.log"
            else
                print_error "❌ フロントエンドログファイルが見つかりません"
            fi
            ;;
        *)
            print_error "使用方法: $0 logs [backend|frontend] follow"
            ;;
    esac
}

show_help() {
    print_header "🚃 WhatTimeNextTrain Termux起動スクリプト"
    print_header "========================================="
    echo ""
    print_info "使用方法: $0 <コマンド> [オプション]"
    echo ""
    print_info "📋 利用可能なコマンド:"
    echo ""
    print_success "  start                    サービスを開始"
    print_success "  stop                     サービスを停止"
    print_success "  restart                  サービスを再起動"
    print_success "  status                   サービス状態を確認"
    print_success "  logs <service> [lines]   ログを表示"
    print_success "  follow <service>         ログをリアルタイム表示"
    print_success "  wakelock <on|off>        Wakelockを制御"
    print_success "  help                     このヘルプを表示"
    echo ""
    print_info "📋 ログコマンドの例:"
    echo ""
    print_info "  $0 logs backend          バックエンドログの最新50行"
    print_info "  $0 logs frontend 100     フロントエンドログの最新100行"
    print_info "  $0 follow backend        バックエンドログをリアルタイム表示"
    echo ""
    print_info "🔋 Wakelockコマンド:"
    echo ""
    print_info "  $0 wakelock on           Wakelockを有効化"
    print_info "  $0 wakelock off          Wakelockを無効化"
    echo ""
    print_warning "💡 ヒント:"
    print_warning "  - 長時間実行する場合は Wakelock を有効にしてください"
    print_warning "  - Termux を閉じるとプロセスが終了する可能性があります"
    print_warning "  - 安定した動作には Termux:Wakelock アプリが推奨されます"
}

# メイン処理
case "$1" in
    start)
        print_header "🚀 WhatTimeNextTrain を起動中..."
        echo ""
        
        # Wakelock の推奨
        if ! [ -f "$PIDS_DIR/wakelock.status" ]; then
            print_warning "💡 より安定した動作のために Wakelock の有効化を推奨します"
            print_info "   コマンド: $0 wakelock on"
            echo ""
        fi
        
        # バックエンド起動
        if start_backend; then
            sleep 3
            # フロントエンド起動
            if start_frontend; then
                echo ""
                print_success "🎉 すべてのサービスが正常に起動しました！"
                echo ""
                show_status
                echo ""
                print_info "🌐 アクセス先URL:"
                print_info "  Webアプリ: http://localhost:3000"
                print_info "  API:      http://localhost:5000"
            else
                print_error "❌ フロントエンドの起動に失敗しました"
                exit 1
            fi
        else
            print_error "❌ バックエンドの起動に失敗しました"
            exit 1
        fi
        ;;
    stop)
        print_header "🛑 WhatTimeNextTrain を停止中..."
        echo ""
        
        stop_service "frontend"
        stop_service "backend"
        
        echo ""
        print_success "🏁 すべてのサービスを停止しました"
        echo ""
        show_status
        ;;
    restart)
        print_header "🔄 WhatTimeNextTrain を再起動中..."
        echo ""
        
        print_info "📍 Step 1: サービス停止"
        stop_service "frontend"
        stop_service "backend"
        
        sleep 2
        
        print_info "📍 Step 2: サービス開始"
        if start_backend; then
            sleep 3
            if start_frontend; then
                echo ""
                print_success "🎉 再起動が完了しました！"
                echo ""
                show_status
            else
                print_error "❌ フロントエンドの再起動に失敗しました"
                exit 1
            fi
        else
            print_error "❌ バックエンドの再起動に失敗しました"
            exit 1
        fi
        ;;
    status)
        show_status
        ;;
    logs)
        if [ "$3" = "follow" ]; then
            follow_logs "$2"
        else
            show_logs "$2" "$3"
        fi
        ;;
    follow)
        follow_logs "$2"
        ;;
    wakelock)
        case "$2" in
            on|enable)
                enable_wakelock
                ;;
            off|disable)
                disable_wakelock
                ;;
            status)
                check_wakelock_status
                ;;
            *)
                print_error "使用方法: $0 wakelock <on|off|status>"
                print_info "  on       Wakelockを有効化"
                print_info "  off      Wakelockを無効化"
                print_info "  status   Wakelock状態を確認"
                ;;
        esac
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "❌ 不明なコマンド: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

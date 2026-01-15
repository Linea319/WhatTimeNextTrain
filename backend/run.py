"""
アプリケーションエントリーポイント

Flaskアプリケーションを起動します
"""
import os
import sys
from app import create_app

app = create_app()

if __name__ == '__main__':
    # 環境モードを確認（DEV または PRODUCTION）
    mode = os.environ.get('APP_MODE', 'DEV').upper()
    debug_mode = mode != 'PRODUCTION'
    
    print("WhatTimeNextTrain バックエンドサーバーを起動中...")
    print(f"モード: {mode}")
    print("API エンドポイント:")
    print("  - GET /api/profiles : プロファイル一覧")
    print("  - GET /api/profile/<name>/next-train : プロファイル指定での次の列車情報")
    print("  - GET /api/profile/<name>/trains : プロファイル指定での全列車情報")
    print("  - GET /api/health : ヘルスチェック")
    print()
    
    app.run(
        host='0.0.0.0',  # Raspberry Pi上でLAN内からアクセス可能にする
        port=5000,
        debug=debug_mode
    )

"""
アプリケーションエントリーポイント

Flaskアプリケーションを起動します
"""
from app import create_app

app = create_app()

if __name__ == '__main__':
    print("WhatTimeNextTrain バックエンドサーバーを起動中...")
    print("API エンドポイント:")
    print("  - GET /api/next-train : 次の列車情報")
    print("  - GET /api/trains : 全ての列車情報")
    print("  - GET /api/config : アプリケーション設定")
    print("  - GET /api/health : ヘルスチェック")
    print()
    
    app.run(
        host='0.0.0.0',  # Raspberry Pi上でLAN内からアクセス可能にする
        port=5000,
        debug=True
    )

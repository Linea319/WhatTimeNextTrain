"""
アプリケーション設定クラス

このクラスはアプリケーション全体の設定を管理します
"""
import os
from datetime import timedelta

class Config:
    """アプリケーションの基本設定クラス"""
    
    # 環境モード
    MODE = os.environ.get('APP_MODE', 'DEV').upper()
    
    # Flask設定
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    DEBUG = MODE != 'PRODUCTION'
    
    # CORS設定 - 環境に応じて切り替え
    if MODE == 'PRODUCTION':
        # 本番環境：ローカルホストのみ許可（Raspberry Pi用）
        CORS_ORIGINS = ['http://localhost:3000', 'http://localhost']
    else:
        # 開発環境：複数のホスト許可
        CORS_ORIGINS = ['http://localhost:3000', 'http://192.168.1.21:3000', 'http://127.0.0.1:3000']
    
    # アプリケーション設定
    PREPARATION_MINUTES = 3       # 準備時間（分）

    # デフォルト値
    HOME_TO_STATION_MINUTES = 10  # 自宅から駅までの徒歩時間（分）
    
    # データファイルパス
    TRAIN_SCHEDULE_PATH = os.path.join(os.path.dirname(__file__), 'data', 'train_schedule.json')
    
    # 更新間隔
    UPDATE_INTERVAL_SECONDS = 60  # 1分間隔で更新

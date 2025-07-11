"""
アプリケーション設定クラス

このクラスはアプリケーション全体の設定を管理します
"""
import os
from datetime import timedelta

class Config:
    """アプリケーションの基本設定クラス"""
    
    # Flask設定
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    DEBUG = True
    
    # CORS設定
    CORS_ORIGINS = ['http://localhost:3000', 'http://localhost:5173']
    
    # アプリケーション設定
    PREPARATION_MINUTES = 3       # 準備時間（分）

    # デフォルト値
    HOME_TO_STATION_MINUTES = 10  # 自宅から駅までの徒歩時間（分）
    
    # データファイルパス
    TRAIN_SCHEDULE_PATH = os.path.join(os.path.dirname(__file__), 'data', 'train_schedule.json')
    
    # 更新間隔
    UPDATE_INTERVAL_SECONDS = 60  # 1分間隔で更新

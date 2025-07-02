"""
Flaskアプリケーションファクトリ

アプリケーションの初期化と設定を行います
"""
from flask import Flask
from flask_cors import CORS
from config import Config

def create_app(config_class=Config):
    """
    Flaskアプリケーションを作成
    
    Args:
        config_class: 設定クラス
        
    Returns:
        Flask: Flaskアプリケーションインスタンス
    """
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # CORS設定
    CORS(app, origins=app.config['CORS_ORIGINS'])
    
    # ルートを登録
    from app.routes import bp
    app.register_blueprint(bp)
    
    return app

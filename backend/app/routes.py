"""
APIルート定義

フロントエンドとの通信用APIエンドポイントを定義します
"""
from flask import Blueprint, jsonify, current_app
from datetime import datetime
from .services.trainScheduler import TrainScheduler

bp = Blueprint('api', __name__, url_prefix='/api')

# グローバルなTrainSchedulerインスタンス
train_scheduler = None

def get_train_scheduler():
    """
    TrainSchedulerのシングルトンインスタンスを取得
    
    Returns:
        TrainScheduler: TrainSchedulerインスタンス
    """
    global train_scheduler
    if train_scheduler is None:
        train_scheduler = TrainScheduler(
            schedule_file_path=current_app.config['TRAIN_SCHEDULE_PATH'],
            home_to_station_minutes=current_app.config['HOME_TO_STATION_MINUTES'],
            preparation_minutes=current_app.config['PREPARATION_MINUTES']
        )
    return train_scheduler

@bp.route('/next-train', methods=['GET'])
def get_next_train():
    """
    次の列車情報を取得するAPIエンドポイント
    
    Returns:
        JSON: 次の列車情報
    """
    try:
        scheduler = get_train_scheduler()
        next_train_info = scheduler.get_next_train_info()
        
        if next_train_info is None:
            return jsonify({
                'error': '時刻表データの読み込みに失敗しました'
            }), 500
        
        # レスポンス用のデータ構造を作成
        response_data = {
            'current_time': next_train_info.current_time,
            'departure_time': next_train_info.departure_time,
            'arrival_time': next_train_info.arrival_time,
            'time_until_departure': next_train_info.time_until_departure,
            'station_name': scheduler.get_station_name(),
            'train': None
        }
        
        if next_train_info.train:
            response_data['train'] = {
                'line': next_train_info.train.line,
                'destination': next_train_info.train.destination,
                'departure_time': next_train_info.train.departure_time,
                'arrival_time': next_train_info.train.arrival_time
            }
        
        return jsonify(response_data)
        
    except Exception as e:
        return jsonify({
            'error': f'エラーが発生しました: {str(e)}'
        }), 500

@bp.route('/trains', methods=['GET'])
def get_all_trains():
    """
    全ての列車情報を取得するAPIエンドポイント
    
    Returns:
        JSON: 全ての列車情報
    """
    try:
        scheduler = get_train_scheduler()
        trains = scheduler.get_all_trains()
        station_name = scheduler.get_station_name()
        
        return jsonify({
            'station_name': station_name,
            'trains': trains
        })
        
    except Exception as e:
        return jsonify({
            'error': f'エラーが発生しました: {str(e)}'
        }), 500

@bp.route('/config', methods=['GET'])
def get_config():
    """
    アプリケーション設定を取得するAPIエンドポイント
    
    Returns:
        JSON: アプリケーション設定
    """
    return jsonify({
        'station_name': current_app.config['STATION_NAME'],
        'home_to_station_minutes': current_app.config['HOME_TO_STATION_MINUTES'],
        'preparation_minutes': current_app.config['PREPARATION_MINUTES'],
        'update_interval_seconds': current_app.config['UPDATE_INTERVAL_SECONDS']
    })

@bp.route('/health', methods=['GET'])
def health_check():
    """
    ヘルスチェック用APIエンドポイント
    
    Returns:
        JSON: サーバー状態
    """
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })

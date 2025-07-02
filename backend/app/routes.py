"""
APIルート定義

フロントエンドとの通信用APIエンドポイントを定義します
"""
from flask import Blueprint, jsonify, current_app, request
from datetime import datetime
import json
import os
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

def load_profile(profile_name):
    """
    プロファイルファイルを読み込む
    
    Args:
        profile_name: プロファイル名
        
    Returns:
        dict: プロファイルデータ
    """
    try:
        profile_path = os.path.join(
            os.path.dirname(current_app.config['TRAIN_SCHEDULE_PATH']),
            'profile',
            f'profile_{profile_name}.json'
        )
        with open(profile_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        raise Exception(f'プロファイル {profile_name} の読み込みに失敗しました: {str(e)}')

def load_schedule_from_profile(profile_data):
    """
    プロファイルデータから時刻表データを読み込む
    
    Args:
        profile_data: プロファイルデータ
        
    Returns:
        dict: 時刻表データ
    """
    try:
        schedule_path = os.path.join(
            os.path.dirname(current_app.config['TRAIN_SCHEDULE_PATH']),
            'schedule',
            profile_data['schedule_file']
        )
        with open(schedule_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        raise Exception(f'時刻表ファイル {profile_data["schedule_file"]} の読み込みに失敗しました: {str(e)}')

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

@bp.route('/profiles', methods=['GET'])
def get_profiles():
    """
    利用可能なプロファイル一覧を取得するAPIエンドポイント
    
    Returns:
        JSON: プロファイル一覧
    """
    try:
        profile_dir = os.path.join(
            os.path.dirname(current_app.config['TRAIN_SCHEDULE_PATH']),
            'profile'
        )
        
        profiles = []
        if os.path.exists(profile_dir):
            for filename in os.listdir(profile_dir):
                if filename.startswith('profile_') and filename.endswith('.json'):
                    profile_name = filename[8:-5]  # "profile_" と ".json" を除去
                    try:
                        profile_data = load_profile(profile_name)
                        profiles.append({
                            'name': profile_name,
                            'departure': profile_data['depature'],
                            'destinations': profile_data.get('my_destinations', [])
                        })
                    except Exception:
                        continue
        
        return jsonify({'profiles': profiles})
        
    except Exception as e:
        return jsonify({
            'error': f'プロファイル一覧の取得に失敗しました: {str(e)}'
        }), 500

@bp.route('/profile/<profile_name>/next-train', methods=['GET'])
def get_next_train_by_profile(profile_name):
    """
    プロファイル指定での次の列車情報を取得するAPIエンドポイント
    
    Args:
        profile_name: プロファイル名
        
    Returns:
        JSON: 次の列車情報
    """
    try:
        # プロファイルデータを読み込み
        profile_data = load_profile(profile_name)
        schedule_data = load_schedule_from_profile(profile_data)
        
        # 専用のTrainSchedulerインスタンスを作成
        scheduler = TrainScheduler(
            schedule_data=schedule_data,
            home_to_station_minutes=current_app.config['HOME_TO_STATION_MINUTES'],
            preparation_minutes=current_app.config['PREPARATION_MINUTES']
        )
        
        next_train_info = scheduler.get_next_train_info()
        
        if next_train_info is None:
            return jsonify({
                'error': '時刻表データの読み込みに失敗しました'
            }), 500
        
        # レスポンス用のデータ構造を作成
        response_data = {
            'profile_name': profile_name,
            'departure_station': profile_data['depature'],
            'current_time': next_train_info.current_time,
            'departure_time': next_train_info.departure_time,
            'arrival_time': next_train_info.arrival_time,
            'time_until_departure': next_train_info.time_until_departure,
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

@bp.route('/profile/<profile_name>/trains', methods=['GET'])
def get_trains_by_profile(profile_name):
    """
    プロファイル指定での全列車情報を取得するAPIエンドポイント
    
    Args:
        profile_name: プロファイル名
        
    Returns:
        JSON: 全ての列車情報
    """
    try:
        # プロファイルデータを読み込み
        profile_data = load_profile(profile_name)
        schedule_data = load_schedule_from_profile(profile_data)
        
        # 専用のTrainSchedulerインスタンスを作成
        scheduler = TrainScheduler(
            schedule_data=schedule_data,
            home_to_station_minutes=current_app.config['HOME_TO_STATION_MINUTES'],
            preparation_minutes=current_app.config['PREPARATION_MINUTES']
        )
        
        trains = scheduler.get_all_trains()
        
        return jsonify({
            'profile_name': profile_name,
            'departure_station': profile_data['depature'],
            'my_destinations': profile_data.get('my_destinations', []),
            'trains': trains
        })
        
    except Exception as e:
        return jsonify({
            'error': f'エラーが発生しました: {str(e)}'
        }), 500

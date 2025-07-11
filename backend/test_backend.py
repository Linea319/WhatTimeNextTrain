"""
バックエンドの基本テスト

開発環境での動作確認用スクリプト
"""
import sys
import os
import json
import glob
from datetime import timedelta
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, time, timedelta
from app.models import Train, TrainSchedule
from app.services.timeCalculator import TimeCalculator
from app.services.trainScheduler import TrainScheduler

def test_models():
    """モデルクラスのテスト"""
    print("=== モデルクラステスト ===")
    
    # Trainクラスのテスト
    train = Train("浅草線", "西馬込", "08:00", "08:30")
    print(f"列車: {train.line} {train.destination} {train.departure_time}-{train.arrival_time}")
    print(f"出発時刻オブジェクト: {train.get_departure_time_obj()}")
    print()

def test_time_calculator():
    """時刻計算サービスのテスト"""
    print("=== 時刻計算サービステスト ===")
    
    calculator = TimeCalculator(home_to_station_minutes=10, preparation_minutes=5)
    
    # 08:30の列車に乗る場合の計算
    train_time = time(8, 30)
    departure_time = calculator.calculate_departure_time(train_time)
    arrival_time = calculator.calculate_arrival_time(departure_time)
    
    print(f"列車出発時刻: {train_time}")
    print(f"自宅出発時刻: {departure_time}")
    print(f"駅到着時刻: {arrival_time}")
    print()

def test_arrival_time_calculation():
    """arrival_time計算の詳細テスト"""
    print("=== arrival_time計算詳細テスト ===")
    
    # 複数の時刻パターンでテスト
    test_cases = [
        (time(8, 0), 10, 5),   # 08:00の列車、移動10分、準備5分
        (time(12, 30), 15, 3), # 12:30の列車、移動15分、準備3分
        (time(18, 45), 8, 7),  # 18:45の列車、移動8分、準備7分
    ]
    
    for i, (train_time, home_to_station, preparation) in enumerate(test_cases, 1):
        print(f"テストケース {i}:")
        calculator = TimeCalculator(home_to_station, preparation)
        
        # 1. 列車出発時刻から家を出る時刻を計算
        departure_time = calculator.calculate_departure_time(train_time)
        
        # 2. 家を出る時刻から駅到着時刻を計算
        arrival_time = calculator.calculate_arrival_time(departure_time)
        
        print(f"  列車出発時刻: {train_time}")
        print(f"  準備時間: {preparation}分")
        print(f"  移動時間: {home_to_station}分")
        print(f"  → 家を出る時刻: {departure_time}")
        print(f"  → 駅到着時刻: {arrival_time}")
        
        # 検証: departure_time + home_to_station_minutes + preparatiom = arrival_time
        departure_datetime = datetime.combine(datetime.today(), departure_time)
        expected_arrival = departure_datetime + timedelta(minutes=home_to_station)
        expected_arrival_time = expected_arrival.time()
        
        if arrival_time == expected_arrival_time:
            print(f"  ✅ 計算正確: {departure_time} + {home_to_station}分 = {arrival_time}")
        else:
            print(f"  ❌ 計算エラー: 期待値 {expected_arrival_time}, 実際 {arrival_time}")
        print()
    
    print()

def test_train_scheduler():
    """列車スケジューラーのテスト（プロファイル対応）"""
    print("=== 列車スケジューラーテスト ===")
    
    # プロファイルディレクトリのパスを確認
    profile_dir = os.path.join(os.path.dirname(__file__), 'data', 'profile')
    schedule_dir = os.path.join(os.path.dirname(__file__), 'data', 'schedule')
    
    print(f"プロファイルディレクトリ: {profile_dir}")
    print(f"スケジュールディレクトリ: {schedule_dir}")
    
    # プロファイルファイルを検索
    profile_files = glob.glob(os.path.join(profile_dir, 'profile_*.json'))
    print(f"利用可能なプロファイル: {len(profile_files)}個")
    
    if not profile_files:
        print("プロファイルファイルが見つかりません")
        return
    
    # 先頭のプロファイルを使用
    first_profile_path = profile_files[0]
    profile_name = os.path.basename(first_profile_path).replace('profile_', '').replace('.json', '')
    print(f"テスト対象プロファイル: {profile_name}")
    
    try:
        # プロファイルデータを読み込み
        with open(first_profile_path, 'r', encoding='utf-8') as f:
            profile_data = json.load(f)
        
        print(f"出発駅: {profile_data.get('depature', 'unknown')}")
        print(f"スケジュールファイル: {profile_data.get('schedule_file', 'unknown')}")
        
        # スケジュールファイルのパスを構築
        schedule_file = profile_data.get('schedule_file')
        if schedule_file:
            schedule_path = os.path.join(schedule_dir, schedule_file)
            print(f"スケジュールファイルパス: {schedule_path}")
            print(f"スケジュールファイル存在確認: {os.path.exists(schedule_path)}")
            
            if os.path.exists(schedule_path):
                # スケジュールデータを読み込み
                with open(schedule_path, 'r', encoding='utf-8') as f:
                    schedule_data = json.load(f)
                
                # TrainSchedulerを初期化（プロファイルの設定値を使用）
                walking_time = int(profile_data.get('walking_time_minutes', 10))
                preparation = int(profile_data.get('preparation_minutes', 5))
                
                scheduler = TrainScheduler(
                    schedule_data=schedule_data,
                    home_to_station_minutes=walking_time,
                    preparation_minutes=preparation
                )
                
                station_name = scheduler.get_station_name()
                print(f"駅名: {station_name}")
                
                # 現在時刻での次の列車情報
                next_train = scheduler.get_next_train_info()
                if next_train:
                    print(f"現在時刻: {next_train.current_time}")
                    print(f"家を出る時刻: {next_train.departure_time}")
                    print(f"駅到着時刻: {next_train.arrival_time}")
                    print(f"出発まで: {next_train.time_until_departure}分")
                    if next_train.train:
                        print(f"列車: {next_train.train.line} {next_train.train.destination} {next_train.train.departure_time}")
                        print(f"arrival_time確認: 家を出る({next_train.departure_time}) + 所要時間({walking_time}分) = 駅到着({next_train.arrival_time})")
                else:
                    print("次の列車情報を取得できませんでした")
            else:
                print("スケジュールファイルが見つかりません")
        else:
            print("プロファイルにスケジュールファイルが指定されていません")
            
    except Exception as e:
        print(f"プロファイル読み込み中にエラーが発生: {e}")
        import traceback
        traceback.print_exc()
    
    print()

if __name__ == "__main__":
    print("WhatTimeNextTrain バックエンドテスト")
    print("=" * 50)
    
    try:
        test_models()
        test_time_calculator()
        test_arrival_time_calculation()
        test_train_scheduler()
        print("テスト完了！")
    except Exception as e:
        print(f"テスト中にエラーが発生しました: {e}")
        import traceback
        traceback.print_exc()

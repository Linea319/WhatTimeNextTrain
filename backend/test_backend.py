"""
バックエンドの基本テスト

開発環境での動作確認用スクリプト
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, time
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

def test_train_scheduler():
    """列車スケジューラーのテスト"""
    print("=== 列車スケジューラーテスト ===")
    
    # データファイルのパスを確認
    data_path = os.path.join(os.path.dirname(__file__), 'data', 'train_schedule.json')
    print(f"データファイルパス: {data_path}")
    print(f"ファイル存在確認: {os.path.exists(data_path)}")
    
    if os.path.exists(data_path):
        scheduler = TrainScheduler(data_path, 10, 5)
        station_name = scheduler.get_station_name()
        print(f"駅名: {station_name}")
        
        # 現在時刻での次の列車情報
        next_train = scheduler.get_next_train_info()
        if next_train:
            print(f"現在時刻: {next_train.current_time}")
            print(f"出発時刻: {next_train.departure_time}")
            print(f"到着時刻: {next_train.arrival_time}")
            print(f"出発まで: {next_train.time_until_departure}分")
            if next_train.train:
                print(f"列車: {next_train.train.line} {next_train.train.destination}")
        else:
            print("次の列車情報を取得できませんでした")
    else:
        print("データファイルが見つかりません")
    print()

if __name__ == "__main__":
    print("WhatTimeNextTrain バックエンドテスト")
    print("=" * 50)
    
    try:
        test_models()
        test_time_calculator()
        test_train_scheduler()
        print("テスト完了！")
    except Exception as e:
        print(f"テスト中にエラーが発生しました: {e}")
        import traceback
        traceback.print_exc()

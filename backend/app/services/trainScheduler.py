"""
列車スケジューラーサービス

列車時刻表の管理と次の列車検索を行います
"""
from typing import Optional
from datetime import datetime
from ..models import TrainSchedule, NextTrainInfo
from .timeCalculator import TimeCalculator

class TrainScheduler:
    """
    列車スケジューラークラス
    
    時刻表データの管理と次の列車情報の提供を行います
    """
    
    def __init__(self, schedule_file_path: str, home_to_station_minutes: int, preparation_minutes: int):
        """
        コンストラクタ
        
        Args:
            schedule_file_path: 時刻表JSONファイルのパス
            home_to_station_minutes: 自宅から駅までの時間（分）
            preparation_minutes: 準備時間（分）
        """
        self.schedule_file_path = schedule_file_path
        self.train_schedule: Optional[TrainSchedule] = None
        self.time_calculator = TimeCalculator(home_to_station_minutes, preparation_minutes)
        self.load_schedule()
    
    def load_schedule(self) -> None:
        """
        時刻表データを読み込み
        
        JSONファイルから時刻表データを読み込みます
        """
        try:
            self.train_schedule = TrainSchedule.from_json_file(self.schedule_file_path)
        except Exception as e:
            print(f"時刻表の読み込みエラー: {e}")
            self.train_schedule = None
    
    def reload_schedule(self) -> None:
        """
        時刻表データを再読み込み
        
        ファイルが更新された場合に時刻表を再読み込みします
        """
        self.load_schedule()
    
    def get_next_train_info(self, current_time: Optional[datetime] = None) -> Optional[NextTrainInfo]:
        """
        次の列車情報を取得
        
        Args:
            current_time: 現在時刻（指定しない場合は現在時刻を使用）
            
        Returns:
            Optional[NextTrainInfo]: 次の列車情報（データが読み込めない場合はNone）
        """
        if self.train_schedule is None:
            return None
        
        return self.time_calculator.find_next_train(self.train_schedule, current_time)
    
    def get_station_name(self) -> Optional[str]:
        """
        駅名を取得
        
        Returns:
            Optional[str]: 駅名（データが読み込めない場合はNone）
        """
        if self.train_schedule is None:
            return None
        return self.train_schedule.station
    
    def get_all_trains(self) -> list:
        """
        全ての列車情報を取得
        
        Returns:
            list: 全ての列車情報のリスト
        """
        if self.train_schedule is None:
            return []
        
        return [
            {
                'line': train.line,
                'destination': train.destination,
                'departure_time': train.departure_time,
                'arrival_time': train.arrival_time
            }
            for train in self.train_schedule.trains
        ]

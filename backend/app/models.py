"""
データモデルクラス

列車データの構造と操作を定義します
"""
from dataclasses import dataclass
from datetime import datetime, time
from typing import List, Optional
import json

@dataclass
class Train:
    """
    列車情報を表すクラス
    
    Attributes:
        line: 路線名
        destination: 行き先
        departure_time: 出発時刻
        arrival_time: 到着時刻
    """
    line: str
    destination: str
    departure_time: str
    arrival_time: str
    
    def get_departure_time_obj(self) -> time:
        """出発時刻をtimeオブジェクトとして取得"""
        hour, minute = map(int, self.departure_time.split(':'))
        return time(hour, minute)
    
    def get_arrival_time_obj(self) -> time:
        """到着時刻をtimeオブジェクトとして取得"""
        hour, minute = map(int, self.arrival_time.split(':'))
        return time(hour, minute)

@dataclass
class TrainSchedule:
    """
    駅の時刻表を表すクラス
    
    Attributes:
        station: 駅名
        trains: 列車リスト
    """
    station: str
    trains: List[Train]
    
    @classmethod
    def from_json_file(cls, file_path: str) -> 'TrainSchedule':
        """
        JSONファイルから時刻表を読み込み
        
        Args:
            file_path: JSONファイルのパス
            
        Returns:
            TrainSchedule: 時刻表オブジェクト
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return cls.from_dict(data)
    
    @classmethod
    def from_dict(cls, data: dict) -> 'TrainSchedule':
        """
        辞書データから時刻表を読み込み
        
        Args:
            data: 時刻表データ辞書
            
        Returns:
            TrainSchedule: 時刻表オブジェクト
        """
        # 新しい構造（schedules）に対応
        if 'schedules' in data:
            trains = []
            current_time = datetime.now()
            is_weekend = current_time.weekday() >= 5  # 土曜日(5)・日曜日(6)
            
            for schedule in data['schedules']:
                schedule_type = schedule.get('type', '')
                
                # 平日/土休日の判定
                if (is_weekend and schedule_type == 'weekend') or (not is_weekend and schedule_type == 'weekday'):
                    for train_data in schedule.get('trains', []):
                        trains.append(Train(**train_data))
                    break
            
            return cls(station=data.get('depature', ''), trains=trains)
        
        # 旧構造（trains）に対応
        elif 'trains' in data:
            trains = [Train(**train_data) for train_data in data['trains']]
            return cls(station=data.get('station', ''), trains=trains)
        
        else:
            raise ValueError("無効なデータ構造です")
    
    def get_trains_after_time(self, target_time: time) -> List[Train]:
        """
        指定時刻以降の列車を取得
        
        Args:
            target_time: 基準時刻
            
        Returns:
            List[Train]: 指定時刻以降の列車リスト
        """
        return [
            train for train in self.trains 
            if train.get_departure_time_obj() >= target_time
        ]

@dataclass
class NextTrainInfo:
    """
    次の列車情報を表すクラス
    
    Attributes:
        current_time: 現在時刻
        departure_time: 出発すべき時刻
        arrival_time: 駅到着時刻
        train: 乗車する列車情報
        time_until_departure: 出発まであと何分か
    """
    current_time: str
    departure_time: str
    arrival_time: str
    train: Optional[Train]
    time_until_departure: int

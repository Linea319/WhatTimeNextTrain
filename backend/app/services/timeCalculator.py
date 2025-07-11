"""
時刻計算サービス

自宅から駅までの移動時間を考慮した時刻計算を行います
"""
from datetime import datetime, time, timedelta
from typing import Optional
from ..models import Train, TrainSchedule, NextTrainInfo

class TimeCalculator:
    """
    時刻計算を行うクラス
    
    自宅から駅までの移動時間と準備時間を考慮して、
    次に乗車できる列車の情報を計算します
    """
    
    def __init__(self, home_to_station_minutes: int, preparation_minutes: int):
        """
        コンストラクタ
        
        Args:
            home_to_station_minutes: 自宅から駅までの時間（分）
            preparation_minutes: 準備時間（分）
        """
        self.home_to_station_minutes = home_to_station_minutes
        self.preparation_minutes = preparation_minutes
        self.total_required_minutes = home_to_station_minutes + preparation_minutes
    
    def calculate_departure_time(self, train_departure_time: time) -> time:
        """
        列車出発時刻から自宅出発時刻を計算
        
        Args:
            train_departure_time: 列車の出発時刻
            
        Returns:
            time: 自宅を出発すべき時刻
        """
        # datetime オブジェクトを作成して計算
        base_datetime = datetime.combine(datetime.today(), train_departure_time)
        departure_datetime = base_datetime - timedelta(minutes=self.total_required_minutes)
        return departure_datetime.time()
    
    def calculate_arrival_time(self, departure_time: time) -> time:
        """
        自宅出発時刻から駅到着時刻を計算
        
        Args:
            departure_time: 自宅出発時刻
            
        Returns:
            time: 駅到着時刻
        """
        base_datetime = datetime.combine(datetime.today(), departure_time)
        arrival_datetime = base_datetime + timedelta(minutes=self.home_to_station_minutes)
        return arrival_datetime.time()
    
    def find_next_train(self, train_schedule: TrainSchedule, current_time: Optional[datetime] = None) -> NextTrainInfo:
        """
        次に乗車できる列車を検索
        
        Args:
            train_schedule: 列車時刻表
            current_time: 現在時刻（指定しない場合は現在時刻を使用）
            
        Returns:
            NextTrainInfo: 次の列車情報
        """
        if current_time is None:
            current_time = datetime.now()
        
        current_time_obj = current_time.time()
        
        # 現在時刻以降に出発できる列車を検索
        for train in train_schedule.trains:
            departure_time = self.calculate_departure_time(train.get_departure_time_obj())
            
            # 現在時刻より後に出発できる列車を見つけた場合
            if departure_time > current_time_obj:
                # 駅への到着時刻を計算（家を出発してから駅に着く時刻）
                station_arrival_time = self.calculate_arrival_time(departure_time)
                
                # 出発まであと何分かを計算
                departure_datetime = datetime.combine(datetime.today(), departure_time)
                time_until_departure = int((departure_datetime - current_time).total_seconds() / 60)
                
                return NextTrainInfo(
                    current_time=current_time.strftime('%H:%M'),
                    departure_time=departure_time.strftime('%H:%M'),
                    arrival_time=station_arrival_time.strftime('%H:%M'),
                    train=train,
                    time_until_departure=time_until_departure
                )
        
        # 今日の列車がない場合
        return NextTrainInfo(
            current_time=current_time.strftime('%H:%M'),
            departure_time="--:--",
            arrival_time="--:--",
            train=None,
            time_until_departure=0
        )

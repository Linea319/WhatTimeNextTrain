"""
北総線の時刻表スクレイピングスクリプト

北総線公式サイトから時刻表データを取得し、JSON形式で保存します
手動実行用：年に一度のダイヤ改正時に実行してください

使用方法:
    python scripts/scrape_hokuso_schedule.py --url "https://..." --output profile_name
    または
    python scripts/scrape_hokuso_schedule.py --profile kitakoku --output-file data/schedule/train_schedule_kitakoku.json
"""

import sys
import json
import re
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Optional

try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    from selenium.webdriver.chrome.options import Options
    from bs4 import BeautifulSoup
except ImportError:
    print("エラー: 必要なライブラリがインストールされていません")
    print("以下のコマンドを実行してください:")
    print("  pip install selenium beautifulsoup4")
    sys.exit(1)


class HokusoScheduleScraper:
    """北総線時刻表スクレイパー"""
    
    # 行き先コードマッピング
    DESTINATION_MAP = {
        '羽': '羽田空港',
        '押': '押上',
        '久': '京急久里浜',
        '三': '三崎口',
        '西': '西馬込',
        '泉': '泉岳寺',
        '品': '品川',
        '矢': '矢切',
    }
    
    def __init__(self, headless: bool = True):
        """
        コンストラクタ
        
        Args:
            headless: ヘッドレスモード（ブラウザウィンドウを表示しない）
        """
        self.headless = headless
        self.driver = None
        self.schedule_data = {
            'depature': '',
            'schedules': [
                {'type': 'weekday', 'trains': []},
                {'type': 'weekend', 'trains': []}
            ]
        }
    
    def setup_driver(self):
        """Selenium WebDriverの初期化"""
        chrome_options = Options()
        if self.headless:
            chrome_options.add_argument('--headless')
        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--disable-blink-features=AutomationControlled')
        chrome_options.add_experimental_option('excludeSwitches', ['enable-automation'])
        chrome_options.add_experimental_option('useAutomationExtension', False)
        
        self.driver = webdriver.Chrome(options=chrome_options)
    
    def close_driver(self):
        """Selenium WebDriverのクローズ"""
        if self.driver:
            self.driver.quit()
    
    def fetch_page(self, url: str) -> str:
        """
        ページをフェッチしてHTMLを取得
        
        Args:
            url: フェッチするURL
            
        Returns:
            HTMLコンテンツ
        """
        print(f"ページを取得中: {url}")
        
        try:
            self.driver.get(url)
            
            # ページが読み込まれるまで待機（最大10秒）
            wait = WebDriverWait(self.driver, 10)
            wait.until(EC.presence_of_all_elements_located((By.TAG_NAME, 'table')))
            
            print("✓ ページの読み込み完了")
            return self.driver.page_source
            
        except Exception as e:
            print(f"✗ ページ取得エラー: {e}")
            raise
    
    def parse_html(self, html: str, is_weekday: bool = True) -> None:
        """
        HTMLを解析して時刻表データを抽出
        
        Args:
            html: HTMLコンテンツ
            is_weekday: 平日データかどうか
        """
        soup = BeautifulSoup(html, 'html.parser')
        
        # 駅名を抽出（平日と土休日の両方に対応）
        name_div = soup.find('div', class_='name_side01') or soup.find('div', class_='name_side02')
        if name_div:
            # "■北総線 北国分 ◇..." のようなフォーマットから駅名を抽出
            title_text = name_div.get_text(strip=True)
            match = re.search(r'■[^◇]*?\s+(\S+?)\s+◇', title_text)
            if match:
                self.schedule_data['depature'] = match.group(1)
        else:
            # フォールバック: title要素から取得
            title = soup.find('title')
            if title:
                title_text = title.get_text(strip=True)
                # "北国分：..." のようなフォーマット
                if '：' in title_text:
                    self.schedule_data['depature'] = title_text.split('：')[0]
        
        # テーブルを探す
        tables = soup.find_all('table')
        if not tables:
            print("✗ テーブルが見つかりません")
            return
        
        # メインのテーブル（時刻表）を処理
        for table in tables:
            trains = self._extract_trains_from_table(table)
            if trains:
                schedule_type = 'weekday' if is_weekday else 'weekend'
                self.schedule_data['schedules'][0 if is_weekday else 1]['trains'] = trains
                print(f"✓ {schedule_type}データを抽出: {len(trains)}本")
                return
    
    def _extract_trains_from_table(self, table) -> List[Dict]:
        """
        テーブルから列車データを抽出
        
        Args:
            table: BeautifulSoupのテーブル要素
            
        Returns:
            列車データのリスト
        """
        trains = []
        rows = table.find_all('tr')
        
        for row in rows:
            # 最初のセル（時間）を取得 - 平日と土休日の両方に対応
            th = row.find('th', class_='side01') or row.find('th', class_='side02')
            td = row.find('td')
            
            if not th or not td:
                continue
            
            hour_str = th.get_text(strip=True)
            
            # 時間でない行はスキップ
            if not hour_str or not hour_str.isdigit():
                continue
            
            hour = int(hour_str)
            
            # tdから列車データを抽出
            trains_in_hour = self._extract_trains_from_td(hour, td)
            trains.extend(trains_in_hour)
        
        return trains
    
    def _extract_trains_from_td(self, hour: int, td) -> List[Dict]:
        """
        tdからdiv.syasyuboxを抽出して列車データを作成
        
        Args:
            hour: 時間
            td: BeautifulSoupのtd要素
            
        Returns:
            列車データのリスト
        """
        trains = []
        
        # td内のすべてのdiv.syasyuboxを探す
        train_boxes = td.find_all('div', class_='syasyubox')
        
        for train_box in train_boxes:
            # span.baikouから行き先コード情報を取得
            bikou = train_box.find('span', class_='bikou')
            minute_span = train_box.find('span', class_='min')
            
            if not bikou or not minute_span:
                continue
            
            bikou_text = bikou.get_text(strip=True)  # "普通 羽" のようなテキスト
            minute_text = minute_span.get_text(strip=True)  # "27" のような数字
            
            # bikou_textから最後の1文字を行き先コードとして抽出
            if bikou_text and minute_text.isdigit():
                destination_code = bikou_text[-1]  # 最後の1文字
                
                if destination_code in self.DESTINATION_MAP:
                    minute = int(minute_text)
                    departure_time = f"{hour}:{minute:02d}"
                    
                    train = {
                        'line': '北総線',
                        'destination': self.DESTINATION_MAP[destination_code],
                        'departure_time': departure_time,
                    }
                    trains.append(train)
        
        return trains
    
    def scrape(self, url: str) -> bool:
        """
        URLから時刻表データをスクレイピング
        
        Args:
            url: スクレイピング対象のURL
            
        Returns:
            成功したかどうか
        """
        try:
            self.setup_driver()
            html = self.fetch_page(url)

            output_log_path = Path(__file__).parent / 'logs' / f'hokuso_schedule_log_{datetime.now().strftime("%Y%m%d_%H%M%S")}.html'
            self.output_log_html(html, str(output_log_path))
            
            # URLにdパラメータがある場合、それが平日/休日の判定
            # dw=0 -> 平日, dw=1 -> 休日など
            is_weekday = '&dw=0' in url or 'dw=0' in url
            
            self.parse_html(html, is_weekday)
            return True
            
        except Exception as e:
            print(f"✗ スクレイピングエラー: {e}")
            return False
            
        finally:
            self.close_driver()
    
    def save_json(self, output_path: str) -> bool:
        """
        JSONファイルとして保存
        
        Args:
            output_path: 出力ファイルパス
            
        Returns:
            成功したかどうか
        """
        try:
            output_file = Path(output_path)
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(self.schedule_data, f, ensure_ascii=False, indent=2)
            
            print(f"✓ ファイルを保存しました: {output_path}")
            return True
            
        except Exception as e:
            print(f"✗ ファイル保存エラー: {e}")
            return False
        
    def output_log_html(self, html: str, log_path: str) -> None:
        """
        ログ用にHTMLを保存
        
        Args:
            html: HTMLコンテンツ
            log_path: ログファイルパス
        """
        try:
            log_file = Path(log_path)
            log_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(log_file, 'w', encoding='utf-8') as f:
                f.write(html)
            
            print(f"✓ ログHTMLを保存しました: {log_path}")
            
        except Exception as e:
            print(f"✗ ログHTML保存エラー: {e}")
    
    def get_schedule_data(self) -> Dict:
        """スケジュールデータを取得"""
        return self.schedule_data


def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(
        description='北総線の時刻表データをスクレイピングします',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
使用例:
  # URLを指定してスクレイピング（平日のみ）
  python scrape_hokuso_schedule.py --url "https://hokuso.ekitan.com/..." --output data/schedule/train_schedule_kitakoku.json
  
  # 平日と土休日の両方のURLを指定（自動で同じファイルに統合）
  python scrape_hokuso_schedule.py --weekday-url "https://hokuso.ekitan.com/...&dw=0" --weekend-url "https://hokuso.ekitan.com/...&dw=1" --output data/schedule/train_schedule_kitakoku.json
  
  # プロファイル名で実行
  python scrape_hokuso_schedule.py --profile kitakoku
        '''
    )
    
    parser.add_argument('--url', type=str, help='スクレイピング対象のURL（単一のURL）')
    parser.add_argument('--weekday-url', type=str, help='平日のスクレイピング対象URL')
    parser.add_argument('--weekend-url', type=str, help='土休日のスクレイピング対象URL')
    parser.add_argument('--output', '-o', type=str, default=None, help='出力ファイルパス')
    parser.add_argument('--profile', type=str, help='プロファイル名（data/profile/profile_*.json）')
    parser.add_argument('--no-headless', action='store_true', help='ブラウザウィンドウを表示')
    
    args = parser.parse_args()
    
    # 出力パスの決定
    if not args.output:
        if args.profile:
            args.output = str(Path(__file__).parent.parent / 'data' / 'schedule' / f'train_schedule_{args.profile}.json')
        elif not args.url and not args.weekday_url:
            print("✗ 出力ファイルパスが指定されていません")
            parser.print_help()
            sys.exit(1)
    
    # スクレイピング実行
    scraper = HokusoScheduleScraper(headless=not args.no_headless)
    
    # 2つのURLで実行する場合（平日と土休日）
    if args.weekday_url and args.weekend_url:
        print(f"■ 北総線時刻表スクレイピング（平日 + 土休日）")
        print(f"  平日URL: {args.weekday_url}")
        print(f"  土休日URL: {args.weekend_url}")
        print(f"  出力: {args.output}")
        print()
        
        # 平日データを取得
        print("[1/2] 平日データを取得中...")
        if not scraper.scrape(args.weekday_url):
            print("✗ 平日データの取得に失敗しました")
            sys.exit(1)
        
        # 土休日データを取得
        print("\n[2/2] 土休日データを取得中...")
        if not scraper.scrape(args.weekend_url):
            print("✗ 土休日データの取得に失敗しました")
            sys.exit(1)
        
        # ファイルに保存
        if scraper.save_json(args.output):
            print("\n✓ スクレイピング完了しました（平日 + 土休日）")
            sys.exit(0)
        else:
            print("\n✗ ファイル保存に失敗しました")
            sys.exit(1)
    
    # 単一のURLで実行する場合
    elif args.url:
        print(f"■ 北総線時刻表スクレイピング")
        print(f"  URL: {args.url}")
        print(f"  出力: {args.output}")
        print()
        
        if scraper.scrape(args.url):
            if scraper.save_json(args.output):
                print("\n✓ スクレイピング完了しました")
                sys.exit(0)
        
        print("\n✗ スクレイピングに失敗しました")
        sys.exit(1)
    
    else:
        print("✗ URLが指定されていません")
        parser.print_help()
        sys.exit(1)


if __name__ == '__main__':
    main()

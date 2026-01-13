# スクレイピング用スクリプト

年に一度のダイヤ改正時に、このディレクトリのスクリプトを実行して時刻表データを更新してください。

## 使用方法

### 前提条件

- `uv` パッケージマネージャーがインストール済み
- `backend/` ディレクトリに仮想環境が作成済み

詳細は [../STARTUP_GUIDE.md](../STARTUP_GUIDE.md) を参照してください。

### 1. スクレイピングスクリプトの実行

#### 方法A: 平日と土休日の両方を取得（推奨）

**Windows (PowerShell):**
```powershell
# backend/scripts ディレクトリに移動して実行
cd backend\scripts
uv run python scrape_hokuso_schedule.py `
  --weekday-url "https://hokuso.ekitan.com/jp/pc/T5?USR=PC&pFlg=1&dw=0&slCode=200-3&d=1" `
  --weekend-url "https://hokuso.ekitan.com/jp/pc/T5?USR=PC&pFlg=1&dw=1&slCode=200-3&d=1" `
  --output ../data/schedule/train_schedule_kitakoku.json
```

**macOS/Linux:**
```bash
# backend/scripts ディレクトリに移動して実行
cd backend/scripts
uv run python scrape_hokuso_schedule.py \
  --weekday-url "https://hokuso.ekitan.com/jp/pc/T5?USR=PC&pFlg=1&dw=0&slCode=200-3&d=1" \
  --weekend-url "https://hokuso.ekitan.com/jp/pc/T5?USR=PC&pFlg=1&dw=1&slCode=200-3&d=1" \
  --output ../data/schedule/train_schedule_kitakoku.json
```

#### 方法B: 単一のURLのみを取得

```bash
cd backend/scripts
uv run python scrape_hokuso_schedule.py --url "https://hokuso.ekitan.com/..." --output ../data/schedule/train_schedule_kitakoku.json
```

#### 方法C: プロファイル名で実行

```bash
cd backend/scripts
uv run python scrape_hokuso_schedule.py --profile kitakoku
```

### 2. ブラウザウィンドウを表示して実行（デバッグ用）

```bash
cd backend/scripts
uv run python scrape_hokuso_schedule.py --weekday-url "..." --weekend-url "..." --output "..." --no-headless
```

## 取得手順

1. 北総線公式サイト（https://hokuso.ekitan.com/）にアクセス
2. 対象の駅と日程を選択
3. 時刻表が表示されたら、ページのURLをコピー

**平日と土休日のURLを両方取得する場合：**
1. 平日（dw=0）のページを開いてURLをコピー
2. 土休日（dw=1）のページを開いてURLをコピー
3. 両方のURLを `--weekday-url` と `--weekend-url` で指定して実行

## 注意事項

- スクレイピングスクリプトは **`backend/scripts/` フォルダから実行してください**
- 本番実行に影響を与えないための分離です
- Selenium でブラウザを操作してデータを取得します
- 実行には Chrome/Chromium ブラウザが必要です
- JavaScriptで動的に描画されるページでも対応しています
- 平日と土休日の両方のデータを取得する場合、`--weekday-url` と `--weekend-url` の両方を指定してください
- 平日と土休日のデータは自動的に同じJSONファイルに統合されます（上書きされません）

## トラブルシューティング

### Chrome/Chromium が見つからない

Chrome をインストールするか、以下のコマンドで chromedriver をダウンロードしてください：

```bash
# Selenium が自動的に管理するバージョンを使用
pip install chromedriver-binary
```

### タイムアウトエラーが出る

ネット接続が遅い場合、スクリプト内の `WebDriverWait` のタイムアウト時間（デフォルト10秒）を増やしてください。

`scrape_hokuso_schedule.py` の `wait.until()` の第2引数を変更:

```python
wait = WebDriverWait(self.driver, 20)  # 20秒に延長
```


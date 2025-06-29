# WhatTimeNextTrain
現在時刻から最寄り駅の次の列車を表示するアプリケーションです

グラフィカルでモダンなUIによって家から駅までの到着時刻とその時刻で乗車できる列車情報をユーザーに分かりやすく表示します

## 技術スタック
### バックエンド
- **Python 3.11** + **Flask 2.3.3**
- **Flask-CORS** - Cross-Origin Resource Sharing対応
- **JSON** - 列車時刻表データの管理
- **APScheduler** - 定期的なデータ更新用

### フロントエンド
- **Vue 3** + **TypeScript**
- **Vite** - 高速ビルドツール
- **Axios** - HTTP クライアント
- **レスポンシブデザイン** - PC・スマートフォン対応

## 動作環境
- **Raspberry Pi**上でホスティング動作するWebアプリケーションです
- Raspberry pi自身のブラウザで表示したり、ローカルLANでスマホから表示することを想定しています
- **Python** + **Flask**によってAPIサーバーを提供
- **Vue 3** + **TypeScript**によるモダンなフロントエンド

## 画面表示内容
- 画面上部にバーに現在時刻とアプリケーションタイトルを表示
- メインの表示部には**自宅**のアイコンと**最寄り駅**が表示され、その上にはそれぞれの**出発時刻**、**到着時刻**を表示
- 最寄り駅の表示には乗車できる列車情報として**路線名**、**行き先**、**出発時刻**、**到着時刻**を表示
- **出発までのカウントダウン**をリアルタイム表示
- **1分毎の自動更新**でデータを常に最新に保持

## プロジェクト構造
```
WhatTimeNextTrain/
├── backend/                 # Pythonバックエンド
│   ├── app/
│   │   ├── __init__.py     # Flaskアプリケーションファクトリ
│   │   ├── routes.py       # APIエンドポイント定義
│   │   ├── models.py       # データモデル
│   │   └── services/       # ビジネスロジック
│   │       ├── timeCalculator.py    # 時刻計算サービス
│   │       └── trainScheduler.py    # 列車スケジューラー
│   ├── data/
│   │   └── train_schedule.json      # 列車時刻表データ
│   ├── config.py           # アプリケーション設定
│   ├── run.py             # サーバー起動スクリプト
│   └── requirements.txt   # Python依存関係
├── frontend/               # Vue.js フロントエンド
│   ├── src/
│   │   ├── components/    # Vueコンポーネント
│   │   ├── services/      # APIサービス
│   │   ├── types/         # TypeScript型定義
│   │   ├── App.vue        # メインコンポーネント
│   │   └── main.ts        # エントリーポイント
│   ├── package.json       # Node.js依存関係
│   └── vite.config.ts     # Vite設定
└── README.md
```

## セットアップ手順

### 1. 必要な環境
- **Python 3.9+**
- **Node.js 16+** (フロントエンド開発用)

### 2. バックエンドのセットアップ
```bash
# プロジェクトディレクトリに移動
cd WhatTimeNextTrain/backend

# Python依存関係をインストール
pip install -r requirements.txt

# サーバーを起動
python run.py
```

### 3. フロントエンドのセットアップ
```bash
# フロントエンドディレクトリに移動
cd WhatTimeNextTrain/frontend

# Node.js依存関係をインストール
npm install

# 開発サーバーを起動
npm run dev
```

## 使用方法

### 1. バックエンドAPI（ポート5000）
- `GET /api/health` - ヘルスチェック
- `GET /api/next-train` - 次の列車情報取得
- `GET /api/trains` - 全列車情報取得
- `GET /api/config` - アプリケーション設定取得

### 2. フロントエンド（ポート3000）
- ブラウザで `http://localhost:3000` にアクセス
- リアルタイムで現在時刻と次の列車情報を表示
- 自動更新により常に最新の情報を提供

## 設定のカスタマイズ

### 移動時間の設定
`backend/config.py` で以下の値を変更できます :
- `HOME_TO_STATION_MINUTES`: 自宅から駅までの徒歩時間（分）
- `PREPARATION_MINUTES`: 準備時間（分）

### 列車時刻表の設定
`backend/data/train_schedule.json` でお住まいの地域の列車時刻表を設定してください。

## 実装済み機能
- ✅ JSON形式の列車時刻表データ管理
- ✅ 移動時間を考慮した時刻計算
- ✅ 次の乗車可能列車の自動検索
- ✅ RESTful API設計
- ✅ Vue 3 + TypeScript フロントエンド
- ✅ レスポンシブデザイン
- ✅ リアルタイム時刻表示
- ✅ 自動データ更新（1分毎）
- ✅ エラーハンドリング
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

### 🚀 自動セットアップ（推奨）

**Windows環境:**
1. PowerShellまたはコマンドプロンプトを管理者権限で開く
2. プロジェクトディレクトリに移動
3. `start-services.ps1` または `start-services.bat` を実行

**Linux/Raspberry Pi環境:**
1. `./setup-raspberry-pi.sh` を実行（初回のみ）
2. `./start-services.sh start` でサービス開始

### 🔧 手動セットアップ

**必要な環境:**
- **Python 3.9+**
- **Node.js 16+** (フロントエンド開発用)

**バックエンドのセットアップ:**
```bash
cd WhatTimeNextTrain/backend
python -m venv venv                    # 仮想環境作成
source venv/bin/activate               # Linux/Mac
# または venv\Scripts\activate        # Windows
pip install -r requirements.txt
python run.py
```

**フロントエンドのセットアップ:**
```bash
cd WhatTimeNextTrain/frontend
npm install
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

## 🚀 クイックスタート

### Windows環境
```powershell
# PowerShellで実行（推奨）
.\start-services.ps1

# または、バッチファイルをダブルクリック
start-services.bat
```

### Linux/Raspberry Pi環境
```bash
# 初回セットアップ
chmod +x setup-raspberry-pi.sh
./setup-raspberry-pi.sh

# サービス起動
./start-services.sh start
```

### 自動化機能
- ✅ **ワンクリック起動** - バックエンドとフロントエンドを同時起動
- ✅ **依存関係の自動確認** - 必要なパッケージの自動インストール
- ✅ **サーバー状態監視** - 起動完了まで自動待機
- ✅ **ログ管理** - 実行ログの自動保存
- ✅ **systemdサービス対応** - Raspberry Pi起動時の自動開始
- ✅ **エラーハンドリング** - 詳細なエラー表示と復旧手順

詳細な使用方法は [STARTUP_GUIDE.md](STARTUP_GUIDE.md) を参照してください。
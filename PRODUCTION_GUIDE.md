# 🏭 本番環境デプロイガイド

本番環境（Ubuntu/Debian サーバー）にWhatTimeNextTrainをデプロイするための完全ガイドです。

## 📋 前提条件

- Ubuntu 20.04 LTS以上またはDebian 11以上
- Python 3.9以上
- Node.js 16以上
- npm 7以上
- Git

## 🚀 クイックスタート

### 1. 前提条件のインストール

```bash
# システム更新
sudo apt update
sudo apt upgrade -y

# Python、Node.js、Gitのインストール
sudo apt install -y python3 python3-venv python3-pip nodejs npm git curl

# uvのインストール（オプション：高速なパッケージ管理）
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2. プロジェクトのクローンと準備

```bash
# プロジェクトのクローン
git clone https://github.com/YOUR_USERNAME/WhatTimeNextTrain.git
cd WhatTimeNextTrain

# ディレクトリパーミッション設定
chmod +x start-services.sh
chmod +x setup-raspberry-pi.sh
```

### 3. 本番環境での起動

#### オプション A: 簡易的な起動（開発用ツール使用）

```bash
# 本番モードで起動
./start-services.sh start --production

# ステータス確認
./start-services.sh status

# 停止
./start-services.sh stop
```

#### オプション B: systemd サービスとして起動（推奨）

システムサービスとして管理することで、サーバー再起動時に自動起動されます。

```bash
# サービス設定ファイルをコピー
sudo cp systemd/whattimenexttrain-backend.service /etc/systemd/system/
sudo cp systemd/whattimenexttrain-frontend.service /etc/systemd/system/

# サービスをリロード
sudo systemctl daemon-reload

# バックエンド起動
sudo systemctl start whattimenexttrain-backend
sudo systemctl enable whattimenexttrain-backend  # 自動起動有効化

# フロントエンド起動
sudo systemctl start whattimenexttrain-frontend
sudo systemctl enable whattimenexttrain-frontend  # 自動起動有効化

# ステータス確認
sudo systemctl status whattimenexttrain-backend
sudo systemctl status whattimenexttrain-frontend

# ログ確認
sudo journalctl -u whattimenexttrain-backend -f
sudo journalctl -u whattimenexttrain-frontend -f
```

#### オプション C: nginx リバースプロキシ（推奨・最高パフォーマンス）

本番環境ではnginxを使用してリバースプロキシを構成することで、より安全で高速な運用が可能になります。

```bash
# nginxインストール
sudo apt install -y nginx

# バックエンド起動
./start-services.sh start --production --no-frontend

# nginx設定ファイルを作成
sudo nano /etc/nginx/sites-available/whattimenexttrain
```

nginx設定例：

```nginx
upstream backend {
    server localhost:5000;
}

server {
    listen 80;
    server_name your_domain.com;  # または IP アドレス

    # フロントエンド（静的ファイル）
    location / {
        root /home/user/WhatTimeNextTrain/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # バックエンド API
    location /api/ {
        proxy_pass http://backend/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
    }

    # キャッシュ設定（静的アセット）
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# サイトを有効化
sudo ln -s /etc/nginx/sites-available/whattimenexttrain /etc/nginx/sites-enabled/

# テスト
sudo nginx -t

# nginxを起動
sudo systemctl start nginx
sudo systemctl enable nginx
```

## 🔧 本番環境設定

### バックエンド設定

環境変数でカスタマイズ可能：

```bash
# APP_MODE=PRODUCTION で本番モード有効化
export APP_MODE=PRODUCTION

# 本番用のシークレットキーを設定
export SECRET_KEY="your-secret-key-here"

# CORS設定はconfig.pyで管理
# PRODUCTION モードではlocalhostのみ許可
```

### フロントエンド設定

`frontend/.env.production`で本番環境時のAPI URLを指定：

```env
VITE_API_BASE_URL=http://your_domain.com/api
```

または、構成ファイル：

```bash
export VITE_API_BASE_URL=http://localhost:5000/api  # nginxの後ろで実行時
```

## 📊 モニタリングとログ

### ログファイル位置

```bash
# 開発環境
./logs/backend.log
./logs/frontend.log

# systemd使用時
sudo journalctl -u whattimenexttrain-backend
sudo journalctl -u whattimenexttrain-frontend
```

### ヘルスチェック

```bash
# バックエンドヘルスチェック
curl http://localhost:5000/api/health

# フロントエンド確認
curl http://localhost:3000

# nginxを通じた確認
curl http://your_domain.com/
curl http://your_domain.com/api/health
```

## 🔒 セキュリティ設定

### ファイアウォール設定

```bash
# UFWを使用（推奨）
sudo ufw default deny incoming
sudo ufw default allow outgoing

# HTTPとHTTPSを許可
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# SSH（管理用）
sudo ufw allow 22/tcp

# ファイアウォール有効化
sudo ufw enable
```

### SSL/TLS設定（Certbotでの自動化）

```bash
# Certbotインストール
sudo apt install -y certbot python3-certbot-nginx

# SSL証明書を取得
sudo certbot certonly --nginx -d your_domain.com

# nginx設定にSSLを追加
sudo certbot --nginx -d your_domain.com

# 自動更新確認
sudo certbot renew --dry-run
```

## 🛠️ トラブルシューティング

### バックエンドが起動しない

```bash
# ログを確認
tail -f logs/backend.log

# ポートが使用中でないか確認
lsof -i :5000

# venv状態を確認
cd backend
source venv/bin/activate
pip list
```

### フロントエンドが表示されない

```bash
# ビルド成功確認
cd frontend
ls -la dist/

# npm buildログ確認
npm run build

# ポート確認
lsof -i :3000
```

### APIが応答しない

```bash
# バックエンドが動作しているか確認
systemctl status whattimenexttrain-backend

# ポート確認
netstat -tuln | grep 5000

# CORS設定を確認
# backend/config.py の PRODUCTION セクションを確認
```

## 📈 パフォーマンス最適化

### Python側の最適化

Gunicornなどの本番用WSGIサーバーの使用（optionalですが推奨）：

```bash
# Gunicornのインストール
cd backend
source venv/bin/activate
pip install gunicorn

# Gunicornで起動
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Node.js側の最適化

```bash
# ビルド時の最適化（package.jsonで確認）
npm run build  # 本番用にミニファイされたコードが生成されます

# サーバーの設定
# nginx使用時は静的ファイルをnginxで提供することで高速化
```

## 🔄 バージョン更新

```bash
# 最新コードを取得
git pull origin main

# 依存関係を更新
cd backend
source venv/bin/activate
uv pip install -r requirements.txt

cd ../frontend
npm install

# サービス再起動
./start-services.sh restart --production

# または systemd使用時
sudo systemctl restart whattimenexttrain-backend
sudo systemctl restart whattimenexttrain-frontend
```

## ❓ よくある質問

**Q: 本番環境と開発環境で何が違いますか？**

A: 主な違いは：
- バックエンドのDEBUGモードが無効化
- Flask開発サーバーではなく本番用ツール使用
- フロントエンドが開発サーバーではなくビルド済みファイルを提供
- CORSがlocalhostのみに制限

**Q: 複数のサーバーで運用できますか？**

A: はい。バックエンドとフロントエンドを別々のサーバーで実行可能です。その場合、フロントエンド側で`VITE_API_BASE_URL`をバックエンドサーバーのURLに設定してください。

**Q: HTTPSはどのように設定しますか？**

A: Certbotを使用してLet's Encryptの無料SSL証明書を取得できます。ガイドの「SSL/TLS設定」セクションを参照してください。

**Q: ログはどこを確認しますか？**

A: systemd使用時は`journalctl`で確認。スクリプト使用時は`logs/`ディレクトリを確認してください。

---

**最終更新:** 2026年1月

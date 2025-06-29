# WhatTimeNextTrain systemd サービス設定
# 
# Raspberry Pi本番環境用のsystemdサービス設定ファイル群

# インストール手順:
# 1. このディレクトリ内のサービスファイルを /etc/systemd/system/ にコピー
# 2. sudo systemctl daemon-reload
# 3. sudo systemctl enable whattimenexttrain-backend.service
# 4. sudo systemctl enable whattimenexttrain-frontend.service
# 5. sudo systemctl start whattimenexttrain-backend.service
# 6. sudo systemctl start whattimenexttrain-frontend.service

# サービス状態確認:
# sudo systemctl status whattimenexttrain-backend.service
# sudo systemctl status whattimenexttrain-frontend.service

# ログ確認:
# sudo journalctl -u whattimenexttrain-backend.service -f
# sudo journalctl -u whattimenexttrain-frontend.service -f

echo "systemdサービス設定ファイル群"
echo "詳細は各.serviceファイルを参照してください"

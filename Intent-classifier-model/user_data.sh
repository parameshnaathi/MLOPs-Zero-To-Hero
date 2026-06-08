#!/bin/bash

set -e

APP_DIR="/opt/intent-app"
REPO_URL="https://github.com/iam-veeramalla/Intent-classifier-model.git"
BRANCH_NAME="virtual-machines"
SERVICE_NAME="intent-gunicorn"

echo "========== Starting User Data Script =========="

echo "========== Step 1: Create application directory =========="
mkdir -p ${APP_DIR}
cd ${APP_DIR}

echo "========== Step 2: Update packages =========="
apt-get update -y

echo "========== Step 3: Install system dependencies =========="
apt-get install -y git python3 python3-venv python3-pip nginx

echo "========== Step 4: Clone application repository =========="
if [ -d ".git" ]; then
    echo "Repository already exists. Pulling latest changes."
    git pull
else
    git clone -b ${BRANCH_NAME} ${REPO_URL} .
fi

echo "========== Step 5: Create Python virtual environment =========="
python3 -m venv .venv

echo "========== Step 6: Activate virtual environment and upgrade pip =========="
source .venv/bin/activate
python3 -m pip install --upgrade pip

echo "========== Step 7: Install Python dependencies =========="
python3 -m pip install -r requirements.txt

echo "========== Step 8: Ensure Gunicorn is installed =========="
python3 -m pip install gunicorn

echo "========== Step 9: Create WSGI file =========="
cat > wsgi.py <<EOF
from app import app

application = app
EOF

echo "========== Step 10: Train model =========="
python3 model/train.py

echo "========== Step 11: Fix ownership =========="
chown -R ubuntu:ubuntu ${APP_DIR}

echo "========== Step 12: Configure Gunicorn systemd service =========="
cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=Gunicorn service for Intent Classifier Flask App
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=${APP_DIR}
Environment="PATH=${APP_DIR}/.venv/bin"
ExecStart=${APP_DIR}/.venv/bin/gunicorn --workers 3 --bind 127.0.0.1:6000 wsgi:application
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "========== Step 13: Configure Nginx reverse proxy =========="
cat > /etc/nginx/conf.d/intent-app.conf <<EOF
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:6000/predict;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "========== Step 14: Remove default Nginx config if present =========="
rm -f /etc/nginx/sites-enabled/default

echo "========== Step 15: Validate Nginx config =========="
nginx -t

echo "========== Step 16: Reload systemd =========="
systemctl daemon-reload

echo "========== Step 17: Enable services =========="
systemctl enable ${SERVICE_NAME}
systemctl enable nginx

echo "========== Step 18: Start services =========="
systemctl restart ${SERVICE_NAME}
systemctl restart nginx

echo "========== Step 19: Show service status =========="
systemctl status ${SERVICE_NAME} --no-pager
systemctl status nginx --no-pager

echo "========== User Data Script Completed Successfully =========="
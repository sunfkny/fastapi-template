#!/bin/bash
set -e
cd "$(dirname "$0")"

SERVICE_NAME="fastapi"
SOCKFILE="uvicorn.sock"
APP="app:app"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME.service"
LOG_PATH="logs/run.log"

SCRIPT_NAME="$(basename "$0")"
mkdir -p "$(dirname "$LOG_PATH")"

if [ -n "$VIRTUAL_ENV" ]; then
    UVICORN=$VIRTUAL_ENV/bin/uvicorn
elif [ -f .venv/bin/uvicorn ]; then
    UVICORN=.venv/bin/uvicorn
elif [ -f venv/bin/uvicorn ]; then
    UVICORN=venv/bin/uvicorn
else
    echo "Virtual environment not found."
    exit 1
fi

if [ -e "$SOCKFILE" ]; then
    systemctl status "$SERVICE_NAME"
    exit 0
fi

if [ ! -f "$SERVICE_PATH" ]; then
    cat <<EOL >"$SERVICE_PATH"
[Unit]
Description=uvicorn $SERVICE_NAME at $PWD
After=network.target

[Service]
Type=simple
WorkingDirectory=$PWD
ExecStart=$PWD/$SCRIPT_NAME
ExecStopPost=/bin/rm -f $PWD/$SOCKFILE
Restart=no
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOL
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME" --now
    systemctl status "$SERVICE_NAME"
    exit 0
fi

"$UVICORN" "$APP" \
    --uds "$SOCKFILE" \
    --no-access-log \
    --proxy-headers \
    --forwarded-allow-ips='*' >>"$LOG_PATH" 2>&1

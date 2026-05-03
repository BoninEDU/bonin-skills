#!/bin/bash
# 安装 bonin-card 依赖
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CARD_DIR="$(dirname "$SCRIPT_DIR")/skills/bonin-card"

if [ -f "$CARD_DIR/package.json" ]; then
    echo "Installing bonin-card dependencies..."
    cd "$CARD_DIR"
    npm install
    npx playwright install chromium
    echo "bonin-card dependencies installed successfully."
else
    echo "Error: package.json not found in $CARD_DIR"
    exit 1
fi

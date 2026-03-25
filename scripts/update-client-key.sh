#!/bin/bash
# Script para atualizar a chave pública nos arquivos de configuração do cliente

set -euo pipefail

PROJECT_ROOT="/opt/zap-remote"
PUBKEY_FILE="${PROJECT_ROOT}/server/data/id_ed25519.pub"
API_CONFIG_FILE="${PROJECT_ROOT}/server/api-data/conf/config.yaml"

CONFIG_FILES=(
    "${PROJECT_ROOT}/client/RustDesk2.toml"
    "${PROJECT_ROOT}/installer/build/RustDesk2.toml"
)

if [ ! -f "$PUBKEY_FILE" ]; then
    echo "ERRO: Chave pública não encontrada!"
    echo "Inicie o servidor primeiro: cd /opt/zap-remote/server && docker compose up -d"
    exit 1
fi

PUBKEY=$(cat "$PUBKEY_FILE")

echo "Atualizando configuração do cliente..."

for config_file in "${CONFIG_FILES[@]}"; do
    if [ -f "$config_file" ]; then
        sed -i "s/^key = \".*\"/key = \"$PUBKEY\"/" "$config_file"
        echo "Atualizado: $config_file"
    fi
done

python3 - "$API_CONFIG_FILE" "$PUBKEY" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
key = sys.argv[2]
text = path.read_text(encoding='utf-8')
updated = re.sub(r'(rustdesk:\s*\n(?:.*\n)*?\s*key:\s*")([^"]*)(")', rf'\1{key}\3', text, count=1)
if updated == text:
    raise SystemExit("Falha ao atualizar rustdesk.key em config.yaml")
path.write_text(updated, encoding='utf-8')
PY

echo ""
echo "Configuração atualizada!"
echo "Chave: $PUBKEY"
echo ""
echo "Agora você pode compilar o instalador Windows."

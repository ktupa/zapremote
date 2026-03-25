#!/bin/bash
# Script para obter a chave pública do servidor RustDesk

PUBKEY_FILE="/opt/zap-remote/server/data/id_ed25519.pub"

echo "============================================"
echo "ZAP Remote - Chave Pública do Servidor"
echo "============================================"
echo ""

if [ -f "$PUBKEY_FILE" ]; then
    PUBKEY=$(cat "$PUBKEY_FILE")
    echo "Chave Pública:"
    echo "$PUBKEY"
    echo ""
    echo "Adicione esta chave no arquivo RustDesk2.toml:"
    echo ""
    echo "key = \"$PUBKEY\""
    echo ""
else
    echo "ERRO: Arquivo de chave não encontrado!"
    echo "Certifique-se de que o servidor está rodando:"
    echo "  cd /opt/zap-remote/server"
    echo "  docker-compose ps"
    exit 1
fi

#!/bin/bash
# Diagnóstico rápido do ambiente ZAP Remote

set -euo pipefail

PROJECT_ROOT="/opt/zap-remote"
SERVER_DIR="${PROJECT_ROOT}/server"
PUBKEY_FILE="${SERVER_DIR}/data/id_ed25519.pub"
API_LOG_FILE="${SERVER_DIR}/api-data/runtime/log.txt"

compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

echo "=== Diagnóstico ZAP Remote ==="
echo ""

echo "1. Status dos Containers:"
if [ -d "$SERVER_DIR" ]; then
    (
        cd "$SERVER_DIR"
        compose ps || true
    )
else
    echo "Diretório do servidor não encontrado: $SERVER_DIR"
fi

echo ""
echo "2. Portas em escuta:"
ss -tulpn | grep -E ':(80|443|21114|21115|21116|21117|21118|21119)\b' || echo "Nenhuma das portas esperadas está em escuta."

echo ""
echo "3. Chave Pública:"
if [ -f "$PUBKEY_FILE" ]; then
    cat "$PUBKEY_FILE"
else
    echo "Chave não encontrada."
fi

echo ""
echo "4. Certificados SSL:"
certbot certificates 2>/dev/null || echo "Certbot não configurado ou sem certificados emitidos."

echo ""
echo "5. API local (porta 21114):"
curl -skI http://127.0.0.1:21114/ | head -n 1 || echo "API local não respondeu."

echo ""
echo "6. Nginx:"
nginx -t 2>&1 || true

echo ""
echo "7. Últimas linhas do log da API:"
if [ -f "$API_LOG_FILE" ]; then
    tail -n 20 "$API_LOG_FILE"
else
    echo "Log da API não encontrado."
fi

echo ""
echo "=== Fim do Diagnóstico ==="
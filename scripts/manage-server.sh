#!/bin/bash
# Script de gerenciamento do servidor RustDesk

set -euo pipefail

cd /opt/zap-remote/server

compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

case "$1" in
    start)
        echo "Iniciando servidor RustDesk..."
        compose up -d
        echo "Servidor iniciado!"
        ;;
    stop)
        echo "Parando servidor RustDesk..."
        compose down
        echo "Servidor parado!"
        ;;
    restart)
        echo "Reiniciando servidor RustDesk..."
        compose restart
        echo "Servidor reiniciado!"
        ;;
    status)
        echo "Status do servidor RustDesk:"
        compose ps
        ;;
    logs)
        echo "Logs do servidor (Ctrl+C para sair):"
        compose logs -f
        ;;
    update)
        echo "Atualizando servidor RustDesk..."
        compose pull
        compose up -d
        echo "Servidor atualizado!"
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status|logs|update}"
        exit 1
        ;;
esac

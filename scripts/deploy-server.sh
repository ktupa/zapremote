#!/bin/bash
# Script de Deploy do RustDesk Server para ZAP Remote
# Ubuntu 20.04+ / Debian 11+

set -euo pipefail

PROJECT_ROOT="/opt/zap-remote"
SERVER_DIR="${PROJECT_ROOT}/server"
API_CONFIG_FILE="${SERVER_DIR}/api-data/conf/config.yaml"
NGINX_SITE_FILE="/etc/nginx/sites-available/rustdesk"

DOMAIN="${ZAP_DOMAIN:-remote.zapprovedor.com.br}"
CERTBOT_EMAIL="${ZAP_CERTBOT_EMAIL:-admin@zapprovedor.com.br}"
JWT_KEY="${ZAP_JWT_KEY:-}"

COMPOSE_CMD=""

echo "============================================"
echo "ZAP Remote - Deploy do Servidor RustDesk"
echo "============================================"
echo ""

detect_compose_cmd() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD=""
    fi
}

compose() {
    if [ -z "$COMPOSE_CMD" ]; then
        detect_compose_cmd
    fi

    if [ "$COMPOSE_CMD" = "docker compose" ]; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

write_http_nginx_config() {
    cat > "$NGINX_SITE_FILE" <<EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        return 200 "ZAP Remote deployment in progress\n";
        add_header Content-Type text/plain;
    }
}
EOF
}

write_https_nginx_config() {
    sed "s/remote\.zapprovedor\.com\.br/${DOMAIN}/g" \
        "${SERVER_DIR}/nginx.conf" > "$NGINX_SITE_FILE"
}

ensure_jwt_key() {
    local effective_jwt_key="$JWT_KEY"

    if [ -z "$effective_jwt_key" ]; then
        effective_jwt_key=$(python3 - "$API_CONFIG_FILE" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding='utf-8').read()
match = re.search(r'jwt:\s*\n\s*key:\s*"([^"]*)"', text)
print(match.group(1) if match else "")
PY
)
    fi

    if [ -z "$effective_jwt_key" ] || [ "$effective_jwt_key" = "change-me-during-deploy" ]; then
        effective_jwt_key=$(openssl rand -hex 32)
    fi

    python3 - "$API_CONFIG_FILE" "$effective_jwt_key" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
secret = sys.argv[2]
text = path.read_text(encoding='utf-8')
updated = re.sub(r'(jwt:\s*\n\s*key:\s*")([^"]*)(")', rf'\1{secret}\3', text, count=1)
if updated == text:
    raise SystemExit("Falha ao atualizar jwt.key em config.yaml")
path.write_text(updated, encoding='utf-8')
PY
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo "ERRO: Execute este script como root (sudo)"
    exit 1
fi

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[1/8]${NC} Atualizando sistema..."
apt-get update && apt-get upgrade -y

echo -e "${GREEN}[2/8]${NC} Instalando dependências..."
apt-get install -y \
    curl \
    wget \
    git \
    openssl \
    python3 \
    python3-bcrypt \
    sqlite3 \
    ufw \
    nginx \
    certbot \
    python3-certbot-nginx

echo -e "${GREEN}[3/8]${NC} Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "Docker já instalado!"
fi

echo -e "${GREEN}[4/8]${NC} Instalando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose já instalado!"
fi

detect_compose_cmd

if [ -z "$COMPOSE_CMD" ]; then
    echo -e "${RED}ERRO:${NC} Docker Compose não está disponível após a instalação."
    exit 1
fi

echo -e "${GREEN}[5/8]${NC} Configurando Firewall (UFW)..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp          # SSH
ufw allow 80/tcp          # HTTP
ufw allow 443/tcp         # HTTPS
ufw allow 21115/tcp       # RustDesk hbbs
ufw allow 21116/tcp       # RustDesk hbbs websocket
ufw allow 21116/udp       # RustDesk hbbs UDP
ufw allow 21117/tcp       # RustDesk hbbr
ufw allow 21118/tcp       # RustDesk API
ufw allow 21119/tcp       # RustDesk hbbr websocket
ufw status

echo -e "${GREEN}[6/8]${NC} Configurando Nginx..."
write_http_nginx_config
ln -sf /etc/nginx/sites-available/rustdesk /etc/nginx/sites-enabled/rustdesk
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx >/dev/null 2>&1 || true
systemctl restart nginx

echo -e "${GREEN}[7/8]${NC} Obtendo certificado SSL..."
echo -e "${YELLOW}IMPORTANTE:${NC} Certifique-se de que o domínio ${DOMAIN} aponta para este servidor!"
read -p "Pressione ENTER para continuar ou CTRL+C para cancelar..."

if [ "$CERTBOT_EMAIL" = "admin@zapprovedor.com.br" ]; then
    echo -e "${YELLOW}AVISO:${NC} Usando email padrão do certbot. Defina ZAP_CERTBOT_EMAIL para personalizar."
fi

certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$CERTBOT_EMAIL" || {
    echo -e "${RED}AVISO:${NC} Falha ao obter certificado SSL. Configure manualmente depois."
}

if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    write_https_nginx_config
    nginx -t
    systemctl reload nginx
else
    echo -e "${YELLOW}AVISO:${NC} Certificado ainda não disponível; Nginx permanecerá em HTTP temporariamente."
fi

echo -e "${GREEN}[8/8]${NC} Iniciando containers RustDesk..."
ensure_jwt_key

cd "$SERVER_DIR"
compose down 2>/dev/null || true
compose up -d

echo ""
echo "============================================"
echo -e "${GREEN}Aguardando servidor inicializar...${NC}"
sleep 10

"${PROJECT_ROOT}/scripts/update-client-key.sh" >/dev/null 2>&1 || true

echo ""
echo "============================================"
echo -e "${GREEN}CHAVE PÚBLICA DO SERVIDOR:${NC}"
echo "============================================"
if [ -f "${SERVER_DIR}/data/id_ed25519.pub" ]; then
    cat "${SERVER_DIR}/data/id_ed25519.pub"
    echo ""
    echo "Copie esta chave e atualize no arquivo:"
    echo "${PROJECT_ROOT}/client/RustDesk2.toml"
else
    echo -e "${YELLOW}Chave não encontrada ainda. Execute:${NC}"
    echo "cat ${SERVER_DIR}/data/id_ed25519.pub"
fi

echo ""
echo "============================================"
echo -e "${GREEN}Deploy concluído com sucesso!${NC}"
echo "============================================"
echo ""
echo "Próximos passos:"
echo "1. Atualize a chave pública no RustDesk2.toml"
echo "2. Compile o instalador Windows"
echo "3. Distribua para os clientes"
echo ""
echo "Comandos úteis:"
echo "  ${COMPOSE_CMD} logs -f    # Ver logs"
echo "  ${COMPOSE_CMD} restart    # Reiniciar"
echo "  ${COMPOSE_CMD} down       # Parar"
echo ""

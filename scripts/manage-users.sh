#!/bin/bash
# ============================================
# ZAP Remote - Gerenciamento de Usuários
# Resolve o bug de hashing de senha da API
# ============================================
# Uso:
#   ./manage-users.sh criar <username> <senha>
#   ./manage-users.sh listar
#   ./manage-users.sh senha <username> <nova_senha>
#   ./manage-users.sh deletar <username>
# ============================================

set -euo pipefail

API_URL="${ZAP_API_URL:-http://127.0.0.1:21114}"
DB_PATH="/opt/zap-remote/server/api-data/data/rustdeskapi.db"
API_LOG_PATH="/opt/zap-remote/server/api-data/runtime/log.txt"
ADMIN_USER="${ZAP_ADMIN_USER:-admin}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

require_dependencies() {
    local missing=0

    for dependency in curl python3 sqlite3; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            echo -e "${RED}Erro:${NC} Dependência ausente: $dependency" >&2
            missing=1
        fi
    done

    if ! python3 -c "import bcrypt" >/dev/null 2>&1; then
        echo -e "${RED}Erro:${NC} Módulo Python 'bcrypt' não encontrado. Instale python3-bcrypt." >&2
        missing=1
    fi

    if [ "$missing" -ne 0 ]; then
        exit 1
    fi
}

discover_admin_password() {
    if [ -n "${ZAP_ADMIN_PASS:-}" ]; then
        printf '%s\n' "$ZAP_ADMIN_PASS"
        return
    fi

    if [ -f "$API_LOG_PATH" ]; then
        awk '/Admin Password Is:/ {print $7; exit}' "$API_LOG_PATH"
    fi
}

build_payload() {
    python3 - "$@" <<'PY'
import json
import sys

keys = sys.argv[1::2]
values = sys.argv[2::2]
print(json.dumps(dict(zip(keys, values))))
PY
}

require_valid_username() {
    local username="$1"

    if [[ ! "$username" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo -e "${RED}Erro:${NC} Use apenas letras, números, ponto, underline e hífen no usuário." >&2
        exit 1
    fi
}

get_admin_token() {
    local token
    local admin_pass

    admin_pass=$(discover_admin_password)
    if [ -z "$admin_pass" ]; then
        echo -e "${RED}Erro:${NC} Defina ZAP_ADMIN_PASS ou garanta que o log da API contenha a senha inicial." >&2
        exit 1
    fi

    token=$(curl -s "${API_URL}/api/admin/login" -X POST \
        -H "Content-Type: application/json" \
        -d "$(build_payload username "$ADMIN_USER" password "$admin_pass")" \
        | python3 -c "import json,sys; print(json.load(sys.stdin)['data']['token'])" 2>/dev/null)
    if [ -z "$token" ]; then
        echo -e "${RED}Erro: Não foi possível obter token admin.${NC}" >&2; exit 1
    fi
    echo "$token"
}

hash_password() {
    python3 - "$1" <<'PY'
import bcrypt
import sys

password = sys.argv[1].encode('utf-8')
print(bcrypt.hashpw(password, bcrypt.gensalt(10)).decode())
PY
}

cmd_criar() {
    local username="$1" password="$2"
    [ ${#password} -lt 4 ] && echo -e "${RED}Erro: Senha mínima 4 caracteres.${NC}" && exit 1
    require_valid_username "$username"
    
    echo -e "${CYAN}Criando usuário '${username}'...${NC}"
    local token=$(get_admin_token)
    
    local result=$(curl -s "${API_URL}/api/admin/user/create" -X POST \
        -H "Content-Type: application/json" -H "Api-Token: ${token}" \
        -d "$(python3 - "$username" <<'PY'
import json
import sys

username = sys.argv[1]
print(json.dumps({
    'username': username,
    'nickname': username,
    'group_id': 1,
    'is_admin': False,
    'status': 1,
}))
PY
)")
    
    local code=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('code',''))" 2>/dev/null || echo "error")
    if [ "$code" != "0" ]; then
        local msg=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('message','Erro'))" 2>/dev/null || echo "$result")
        echo -e "${RED}Erro: ${msg}${NC}"; exit 1
    fi
    
    # Corrigir senha via SQLite (bcrypt correto)
    local hash=$(hash_password "$password")
    sqlite3 "$DB_PATH" "UPDATE users SET password='${hash}' WHERE username='${username}';"
    
    local login_test=$(curl -s "${API_URL}/api/login" -X POST \
        -H "Content-Type: application/json" \
        -d "$(build_payload username "$username" password "$password")")
    
    if echo "$login_test" | grep -q "access_token"; then
        echo -e "${GREEN}Usuário '${username}' criado com sucesso! Login verificado.${NC}"
    else
        echo -e "${YELLOW}Usuário criado. Senha atualizada no banco.${NC}"
    fi
}

cmd_listar() {
    local token=$(get_admin_token)
    echo -e "${CYAN}=== Usuários ZAP Remote ===${NC}"
    echo ""
    curl -s "${API_URL}/api/admin/user/list" -H "Api-Token: ${token}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
users = data['data']['list']
print(f'Total: {len(users)} usuários')
print(f'{\"ID\":<5} {\"Usuário\":<20} {\"Apelido\":<20} {\"Admin\":<8} {\"Status\":<10} {\"Criado em\":<20}')
print('-' * 85)
for u in users:
    admin = 'Sim' if u['is_admin'] else 'Não'
    status = 'Ativo' if u['status'] == 1 else 'Inativo'
    print(f'{u[\"id\"]:<5} {u[\"username\"]:<20} {u[\"nickname\"]:<20} {admin:<8} {status:<10} {u[\"created_at\"]:<20}')
"
}

cmd_senha() {
    local username="$1" new_password="$2"
    [ ${#new_password} -lt 4 ] && echo -e "${RED}Erro: Senha mínima 4 caracteres.${NC}" && exit 1
    require_valid_username "$username"
    
    echo -e "${CYAN}Alterando senha de '${username}'...${NC}"
    local exists=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM users WHERE username='${username}';")
    [ "$exists" -eq 0 ] && echo -e "${RED}Erro: Usuário '${username}' não encontrado.${NC}" && exit 1
    
    local hash=$(hash_password "$new_password")
    sqlite3 "$DB_PATH" "UPDATE users SET password='${hash}' WHERE username='${username}';"
    
    local login_test=$(curl -s "${API_URL}/api/login" -X POST \
        -H "Content-Type: application/json" \
        -d "$(build_payload username "$username" password "$new_password")")
    
    if echo "$login_test" | grep -q "access_token"; then
        echo -e "${GREEN}Senha de '${username}' alterada com sucesso!${NC}"
    else
        echo -e "${YELLOW}Senha atualizada. Pode ser necessário reiniciar a API.${NC}"
    fi
}

cmd_deletar() {
    local username="$1"
    [ "$username" = "admin" ] && echo -e "${RED}Erro: Não pode deletar admin.${NC}" && exit 1
    require_valid_username "$username"
    
    local token=$(get_admin_token)
    local user_id=$(curl -s "${API_URL}/api/admin/user/list" -H "Api-Token: ${token}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for u in data['data']['list']:
    if u['username'] == '${username}':
        print(u['id']); break
" 2>/dev/null)
    
    [ -z "$user_id" ] && echo -e "${RED}Erro: Usuário '${username}' não encontrado.${NC}" && exit 1
    
    echo -e "${CYAN}Deletando '${username}' (ID: ${user_id})...${NC}"
    local result=$(curl -s "${API_URL}/api/admin/user/delete" -X POST \
        -H "Content-Type: application/json" -H "Api-Token: ${token}" -d "{\"id\":${user_id}}")
    
    local code=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('code',''))" 2>/dev/null || echo "error")
    [ "$code" = "0" ] && echo -e "${GREEN}Usuário '${username}' deletado!${NC}" || echo -e "${RED}Erro: ${result}${NC}"
}

show_usage() {
    echo -e "${CYAN}ZAP Remote - Gerenciamento de Usuários${NC}"
    echo ""
    echo "Uso:"
    echo "  $0 criar <username> <senha>     - Criar novo usuário"
    echo "  $0 listar                        - Listar todos"
    echo "  $0 senha <username> <nova_senha> - Alterar senha"
    echo "  $0 deletar <username>            - Deletar usuário"
}

[ $# -lt 1 ] && show_usage && exit 0

require_dependencies

case "$1" in
    criar|create)
        [ $# -lt 3 ] && echo -e "${RED}Uso: $0 criar <username> <senha>${NC}" && exit 1
        cmd_criar "$2" "$3" ;;
    listar|list)
        cmd_listar ;;
    senha|password)
        [ $# -lt 3 ] && echo -e "${RED}Uso: $0 senha <username> <nova_senha>${NC}" && exit 1
        cmd_senha "$2" "$3" ;;
    deletar|delete)
        [ $# -lt 2 ] && echo -e "${RED}Uso: $0 deletar <username>${NC}" && exit 1
        cmd_deletar "$2" ;;
    *)
        show_usage; exit 1 ;;
esac

# Changelog - ZAP Remote

Todas as mudanças notáveis do projeto serão documentadas neste arquivo.

## [Unreleased]

### Corrigido
- Fluxo de deploy do Nginx/Certbot para não depender de certificados antes da emissão
- Geração automática de `jwt.key` no deploy quando o valor ainda não foi definido
- Sincronização da chave pública entre cliente, build do instalador e configuração da API
- Compatibilidade dos scripts com `docker-compose` e `docker compose`
- Criação do script `diagnose.sh`, já referenciado pela documentação
- Proxy WSS no Nginx para clientes mobile, com correção dos caminhos `/ws/id` e `/ws/relay`

### Segurança
- `manage-users.sh` agora lê a senha administrativa de variável de ambiente ou do log da API, em vez de fixá-la no código
- `manage-users.sh` valida dependências e trata senhas com escaping seguro no hashing e nas chamadas HTTP

## [1.0.0] - 2026-03-21

### Adicionado
- Sistema completo de acesso remoto baseado em RustDesk
- Servidor Docker com hbbs e hbbr
- Configuração automática via docker-compose
- Script de deploy automatizado (deploy-server.sh)
- Configuração de cliente (RustDesk2.toml)
- Instalador Windows com Inno Setup
- Script de instalação manual (.bat)
- Configuração de Nginx com SSL
- Firewall (UFW) pré-configurado
- Scripts de gerenciamento do servidor
- Documentação completa em português
- Guia de troubleshooting
- Guia de configuração de DNS
- Guia de compilação do instalador Windows
- Identidade visual e branding
- Domínio personalizado: remote.zapprovedor.com.br

### Segurança
- Certificados SSL via Let's Encrypt
- Comunicação criptografada end-to-end
- Autenticação via chave ED25519
- Firewall configurado com portas específicas
- Headers de segurança no Nginx

### Scripts
- `deploy-server.sh` - Deploy completo automatizado
- `manage-server.sh` - Gerenciamento (start/stop/restart/logs)
- `manage-users.sh` - Gerenciamento de usuários da API
- `get-public-key.sh` - Obter chave pública do servidor
- `update-client-key.sh` - Atualizar chave no cliente
- `diagnose.sh` - Diagnóstico automático de problemas

### Documentação
- README.md - Visão geral do projeto
- QUICK-START.md - Guia de início rápido (5 minutos)
- WINDOWS-BUILD.md - Compilação do instalador Windows
- DNS-CONFIG.md - Configuração de DNS
- TROUBLESHOOTING.md - Solução de problemas
- BRANDING.md - Identidade visual
- CHANGELOG.md - Histórico de mudanças

### Configurações
- Docker Compose com restart automático
- Portas: 21115, 21116, 21117, 21118, 21119
- Nginx como proxy reverso
- SSL/TLS obrigatório
- Logs estruturados

---

## Formato

Baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/)

### Tipos de Mudanças
- `Adicionado` para novas funcionalidades
- `Modificado` para mudanças em funcionalidades existentes
- `Depreciado` para funcionalidades que serão removidas
- `Removido` para funcionalidades removidas
- `Corrigido` para correções de bugs
- `Segurança` para vulnerabilidades corrigidas

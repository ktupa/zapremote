# ZAP Remote - Sistema de Acesso Remoto

Sistema completo de acesso remoto baseado no RustDesk, com servidor próprio, cliente customizado e instalador automatizado.

## 📋 Visão Geral

Este projeto substitui soluções comerciais (AnyDesk/TeamViewer) por uma solução própria e gratuita:

- **Servidor Próprio**: Controle total dos dados
- **Cliente Customizado**: Marca ZAP Provedor
- **Instalação Automatizada**: Deploy com um comando
- **Seguro**: SSL/TLS com Let's Encrypt
- **Domínio Próprio**: remote.zapprovedor.com.br

## 🗂️ Estrutura do Projeto

```
/opt/zap-remote/
├── server/              # Servidor RustDesk
│   ├── docker-compose.yml
│   ├── nginx.conf
│   └── data/           # Dados e chaves (gerado automaticamente)
├── client/             # Configuração do cliente
│   └── RustDesk2.toml
├── installer/          # Instaladores Windows
│   ├── ZAPRemote-Setup.iss
│   └── install-manual.bat
├── scripts/            # Scripts de gerenciamento
│   ├── deploy-server.sh
│   ├── diagnose.sh
│   ├── manage-server.sh
│   ├── manage-users.sh
│   ├── get-public-key.sh
│   └── update-client-key.sh
├── docs/              # Documentação
└── branding/          # Identidade visual
```

## 🚀 Quick Start

### 1. Deploy do Servidor (Ubuntu/Debian)

```bash
# Execute como root
cd /opt/zap-remote/scripts
./deploy-server.sh
```

Este script irá:
- Instalar Docker e Docker Compose
- Configurar firewall (UFW)
- Configurar Nginx com SSL
- Iniciar containers RustDesk
- Exibir a chave pública do servidor

### 2. Obter Chave Pública

```bash
/opt/zap-remote/scripts/get-public-key.sh
```

### 3. Atualizar Configuração do Cliente

```bash
/opt/zap-remote/scripts/update-client-key.sh
```

### 4. Compilar Instalador Windows

Veja [docs/WINDOWS-BUILD.md](docs/WINDOWS-BUILD.md)

## 📡 Portas Utilizadas

| Porta | Protocolo | Serviço | Descrição |
|-------|-----------|---------|-----------|
| 21114 | TCP | rustdesk-api | API administrativa local |
| 21115 | TCP | hbbs | Servidor de rendezvous |
| 21116 | TCP/UDP | hbbs | WebSocket e NAT |
| 21117 | TCP | hbbr | Relay server |
| 21118 | TCP | hbbs | API HTTP |
| 21119 | TCP | hbbr | WebSocket relay |
| 80 | TCP | Nginx | HTTP (redireciona para HTTPS) |
| 443 | TCP | Nginx | HTTPS |

## 🔧 Gerenciamento do Servidor

```bash
# Iniciar servidor
/opt/zap-remote/scripts/manage-server.sh start

# Parar servidor
/opt/zap-remote/scripts/manage-server.sh stop

# Reiniciar servidor
/opt/zap-remote/scripts/manage-server.sh restart

# Ver status
/opt/zap-remote/scripts/manage-server.sh status

# Ver logs
/opt/zap-remote/scripts/manage-server.sh logs

# Atualizar
/opt/zap-remote/scripts/manage-server.sh update

# Diagnóstico rápido
/opt/zap-remote/scripts/diagnose.sh

# Gerenciar usuários da API
/opt/zap-remote/scripts/manage-users.sh listar
```

## 📚 Documentação Completa

- [Guia de Deploy do Servidor](docs/DEPLOY-SERVER.md)
- [Compilação do Instalador Windows](docs/WINDOWS-BUILD.md)
- [Configuração de DNS](docs/DNS-CONFIG.md)
- [Solução de Problemas](docs/TROUBLESHOOTING.md)
- [Branding e Identidade Visual](docs/BRANDING.md)

## 🎨 Identidade Visual

**Nome**: ZAP Remote  
**Slogan**: "Acesso remoto seguro e confiável"  
**Cores**: Azul tecnológico (#0066CC) e Verde ativo (#00CC66)

## 🔐 Segurança

- ✅ Certificado SSL/TLS (Let's Encrypt)
- ✅ Firewall configurado (UFW)
- ✅ Comunicação criptografada end-to-end
- ✅ Chaves ED25519 para autenticação
- ✅ Servidor próprio (sem dependência de terceiros)

## 📱 Compatibilidade Mobile

Clientes Android/iPhone neste ambiente precisam de WSS funcionando no Nginx.

Os endpoints publicados são:

- `/ws/id` -> `127.0.0.1:21118/`
- `/ws/relay` -> `127.0.0.1:21119/`

Sem esse proxy WSS, o desktop pode continuar funcionando, mas o celular pode falhar na conexão.

## 📞 Suporte

Para suporte técnico, entre em contato:
- Email: suporte@zapprovedor.com.br
- Site: https://zapprovedor.com.br

## 📄 Licença

Este projeto é baseado em RustDesk (AGPLv3).  
Customizações © 2026 ZAP Provedor

---

**Desenvolvido por ZAP Provedor**  
Acesse: https://zapprovedor.com.br

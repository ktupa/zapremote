# 🚀 ZAP Remote - Início Rápido (5 Minutos)

Guia ultra-rápido para colocar o ZAP Remote em produção.

## ✅ Checklist Pré-Deploy

- [ ] VPS Ubuntu/Debian com IP público
- [ ] Domínio `remote.zapprovedor.com.br` apontando para o servidor
- [ ] Acesso root ao servidor
- [ ] Portas 80, 443, 21115-21119 liberadas no provedor de VPS

## 📍 Passo 1: Configurar DNS (Faça ANTES)

No seu provedor de DNS, adicione:

```
Tipo: A
Nome: remote
Valor: [IP_DO_SEU_SERVIDOR]
TTL: 3600
```

Aguarde 10-30 minutos e teste:
```bash
nslookup remote.zapprovedor.com.br
```

## 🖥️ Passo 2: Deploy do  Servidor

```bash
# Como root
cd /opt/zap-remote/scripts
./deploy-server.sh
```

Se precisar sobrescrever o domínio, email do certbot ou a chave JWT no deploy:

```bash
ZAP_DOMAIN=remote.zapprovedor.com.br \
ZAP_CERTBOT_EMAIL=admin@zapprovedor.com.br \
./deploy-server.sh
```

**O script faz TUDO automaticamente:**
- Instala Docker
- Configura firewall
- Configura Nginx + SSL
- Inicia RustDesk Server
- Exibe a chave pública

⏱️ **Tempo estimado**: 5-10 minutos

## 🔑 Passo 3: Copiar Chave Pública

Ao final do deploy, copie a chave exibida:

```
============================================
CHAVE PÚBLICA DO SERVIDOR:
============================================
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Ou execute:
```bash
/opt/zap-remote/scripts/get-public-key.sh
```

## 🔄 Passo 4: Atualizar Configuração do Cliente

```bash
/opt/zap-remote/scripts/update-client-key.sh
```

Este script atualiza automaticamente o arquivo `RustDesk2.toml`.

## 💻 Passo 5: Preparar Instalador Windows

### No Servidor Linux:

```bash
# Baixar arquivo de configuração
cat /opt/zap-remote/client/RustDesk2.toml
```

Copie o conteúdo.

### No Windows:

1. **Baixar RustDesk:**
   - https://github.com/rustdesk/rustdesk/releases
   - Pegue: `rustdesk-x86_64.exe`

2. **Criar pasta:**
   ```
   C:\ZAPRemote-Build\
   ```

3. **Copiar arquivos do servidor:**
   - `RustDesk2.toml` (já atualizado com a chave)
   - `ZAPRemote-Setup.iss`
   - `install-manual.bat`

4. **Renomear executável:**
   ```
   rustdesk-x86_64.exe → rustdesk.exe
   ```

5. **Instalar Inno Setup:**
   - https://jrsoftware.org/isdl.php

6. **Compilar:**
   - Abrir `ZAPRemote-Setup.iss` no Inno Setup
   - Build → Compile
   - Instalador em `output\ZAPRemote-Setup.exe`

## ✅ Passo 6: Testar

### Testar Servidor:

```bash
# Ver status
/opt/zap-remote/scripts/manage-server.sh status

# Ver logs
/opt/zap-remote/scripts/manage-server.sh logs
```

### Testar Cliente:

1. Instalar `ZAPRemote-Setup.exe` em um PC Windows
2. Abrir ZAP Remote
3. Verificar se conecta automaticamente ao servidor

## 🎯 Pronto!

Agora você tem:

✅ Servidor RustDesk rodando  
✅ SSL configurado  
✅ Cliente customizado  
✅ Instalador automatizado  

## 📦 Distribuir para Clientes

1. Hospedar instalador:
```bash
cp /caminho/ZAPRemote-Setup.exe /var/www/html/
```

2. Enviar link:
```
https://zapprovedor.com.br/ZAPRemote-Setup.exe
```

3. Instruir cliente:
   - Baixar
   - Executar como Administrador
   - Pronto!

## 🔧 Comandos Úteis

```bash
# Iniciar
/opt/zap-remote/scripts/manage-server.sh start

# Parar
/opt/zap-remote/scripts/manage-server.sh stop

# Reiniciar
/opt/zap-remote/scripts/manage-server.sh restart

# Ver logs
/opt/zap-remote/scripts/manage-server.sh logs

# Atualizar
/opt/zap-remote/scripts/manage-server.sh update

# Ver chave
/opt/zap-remote/scripts/get-public-key.sh
```

## 🆘 Problemas?

```bash
# Diagnóstico automático
/opt/zap-remote/scripts/diagnose.sh

# Reset completo
cd /opt/zap-remote/server
docker-compose down -v
rm -rf data/*
docker-compose up -d
```

Veja: [Troubleshooting](docs/TROUBLESHOOTING.md)

## 📚 Documentação Completa

- [README Principal](README.md)
- [Deploy Detalhado](docs/DEPLOY-SERVER.md)
- [Build Windows](docs/WINDOWS-BUILD.md)
- [Configuração DNS](docs/DNS-CONFIG.md)
- [Branding](docs/BRANDING.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 💡 Dicas Finais

1. **Backup**: Fazer backup de `/opt/zap-remote/server/data/id_ed25519*`
2. **Monitoramento**: Configure alertas para o servidor
3. **Atualizações**: Execute `manage-server.sh update` mensalmente
4. **Logs**: Monitore logs regularmente
5. **Segurança**: Mantenha firewall ativo

---

**Suporte**: suporte@zapprovedor.com.br  
**Desenvolvido por**: ZAP Provedor

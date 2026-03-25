# Solução de Problemas - ZAP Remote

Guia para resolver problemas comuns do ZAP Remote.

## 🔍 Diagnóstico Rápido

### Verificar Status do Servidor

```bash
# Status dos containers
cd /opt/zap-remote/server
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f

# Verificar portas abertas
netstat -tulpn | grep "21115\|21116\|21117"
```

### Testar Conectividade

```bash
# Testar porta hbbs
telnet remote.zapprovedor.com.br 21115

# Testar porta relay
telnet remote.zapprovedor.com.br 21117

# Testar resolução DNS
nslookup remote.zapprovedor.com.br
```

## 🐛 Problemas Comuns - Servidor

### 1. Containers não iniciam

**Sintomas:**
```
ERROR: Cannot start service hbbs
```

**Solução:**
```bash
# Verificar logs
docker-compose logs hbbs hbbr

# Parar tudo e reiniciar
docker-compose down
docker-compose up -d

# Verificar se portas estão em uso
sudo lsof -i :21115
sudo lsof -i :21116
sudo lsof -i :21117
```

### 2. Chave pública não aparece

**Sintomas:**
- Arquivo `id_ed25519.pub` não existe

**Solução:**
```bash
# Aguardar alguns segundos após iniciar
sleep 10

# Verificar se arquivo foi criado
ls -la /opt/zap-remote/server/data/

# Se não existe, verificar logs
docker-compose logs hbbs | grep -i "key\|error"

# Recriar containers
docker-compose down
rm -rf /opt/zap-remote/server/data/*
docker-compose up -d
```

### 3. Firewall bloqueando conexões

**Sintomas:**
- Cliente não consegue conectar
- Timeout ao tentar estabelecer conexão

**Solução:**
```bash
# Verificar status do UFW
sudo ufw status verbose

# Reconfigurar portas
sudo ufw allow 21115/tcp
sudo ufw allow 21116/tcp
sudo ufw allow 21116/udp
sudo ufw allow 21117/tcp
sudo ufw allow 21118/tcp
sudo ufw allow 21119/tcp
sudo ufw reload

# Se usar iptables
sudo iptables -L -n | grep 21115
```

### 4. SSL não funciona

**Sintomas:**
```
ERROR: Certificate verification failed
```

**Solução:**
```bash
# Verificar certificados
sudo certbot certificates

# Renovar certificado
sudo certbot renew

# Testar Nginx
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx

# Verificar logs do Nginx
sudo tail -f /var/log/nginx/error.log
```

### 5. DNS não resolve

**Sintomas:**
- `nslookup` não retorna IP

**Solução:**
1. Verifique configuração no provedor de DNS
2. Aguarde propagação (até 48h)
3. Teste com DNS público:
```bash
nslookup remote.zapprovedor.com.br 8.8.8.8
```

4. Temporariamente use IP direto no `RustDesk2.toml`

### 6. Celular não conecta, desktop conecta

**Sintomas:**
- Android/iPhone falha ao conectar
- Desktop continua conectando normalmente

**Causa provável:**
- WSS não publicado no Nginx
- Ou `proxy_pass` dos caminhos `/ws/id` e `/ws/relay` encaminhando para o backend sem reescrever o caminho

**Solução:**
No vhost do Nginx, garanta exatamente:

```nginx
location /ws/id {
    proxy_pass http://127.0.0.1:21118/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
}

location /ws/relay {
    proxy_pass http://127.0.0.1:21119/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
}
```

Depois valide:

```bash
nginx -t
systemctl reload nginx

curl --http1.1 -kis \
  -H 'Connection: Upgrade' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  https://remote.zapprovedor.com.br/ws/id | head
```

O resultado esperado é `101 Switching Protocols`.

## 🐛 Problemas Comuns - Cliente Windows

### 1. Cliente não conecta ao servidor

**Sintomas:**
- "Connection failed"
- "Server unreachable"

**Solução:**

1. **Verificar configuração:**
```
%APPDATA%\RustDesk\config\RustDesk2.toml
```

2. **Verificar conectividade:**
```cmd
ping remote.zapprovedor.com.br
telnet remote.zapprovedor.com.br 21115
```

3. **Verificar firewall Windows:**
   - Painel de Controle → Windows Defender Firewall
   - Permitir RustDesk através do firewall

4. **Desabilitar antivírus temporariamente** (para teste)

### 2. Chave pública incorreta

**Sintomas:**
- "Invalid key"
- "Authentication failed"

**Solução:**

1. Obter chave correta no servidor:
```bash
/opt/zap-remote/scripts/get-public-key.sh
```

2. Atualizar no `RustDesk2.toml`:
```toml
key = "CHAVE_CORRETA_AQUI"
```

3. Recompilar instalador com chave atualizada

### 3. Instalação falha

**Sintomas:**
- Erro durante Setup
- "Access denied"

**Solução:**
1. Executar como Administrador
2. Desabilitar antivírus temporariamente
3. Verificar espaço em disco
4. Tentar instalação manual com `install-manual.bat`

### 4. Serviço não inicia automaticamente

**Solução:**
```cmd
# Verificar serviço (como Admin)
sc query RustDesk

# Iniciar manualmente
sc start RustDesk

# Configurar para iniciar automaticamente
sc config RustDesk start= auto

# Ou reinstalar chamando:
"C:\Program Files\ZAP Remote\rustdesk.exe" --install-service
```

### 5. Antivírus bloqueia instalação

**Sintomas:**
- Arquivo excluído após download
- "Threat detected"

**Solução:**
1. Adicionar exceção no antivírus
2. Enviar instalador para análise (falso positivo):
   - VirusTotal: https://www.virustotal.com
   - Microsoft: https://www.microsoft.com/wdsi/filesubmission

3. Considerar assinar executável com certificado de código

## 🐛 Problemas de Performance

### 1. Conexão lenta

**Possíveis causas:**
- Latência de rede alta
- Servidor sobrecarregado
- Cliente com recursos insuficientes

**Solução:**
```bash
# Verificar recursos do servidor
top
htop
docker stats

# Ajustar qualidade no cliente
# (Configurações → Qualidade → Balanceada/Baixa)

# Verificar latência
ping remote.zapprovedor.com.br
```

### 2. Alto uso de CPU

**Solução:**
```bash
# Limitar recursos dos containers
# Edite docker-compose.yml
services:
  hbbs:
    ...
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

### 3. Logs muito grandes

**Solução:**
```bash
# Limpar logs antigos
docker-compose down
truncate -s 0 /opt/zap-remote/server/data/*.log

# Configurar rotação de logs
cat > /opt/zap-remote/server/docker-compose.yml << 'EOF'
...
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
EOF
```

## 🔧 Ferramentas de Diagnóstico

### Script de Diagnóstico Automático

Use `/opt/zap-remote/scripts/diagnose.sh`:

```bash
/opt/zap-remote/scripts/diagnose.sh
```

### Habilitar Debug

No servidor:
```bash
# Editar docker-compose.yml
environment:
  - RUST_LOG=debug

# Reiniciar
docker-compose restart
```

No cliente (Windows):
```
rustdesk.exe --log-level debug
```

## 📞 Suporte Adicional

### Logs do Cliente

Windows:
```
%APPDATA%\RustDesk\logs\
```

### Logs do Servidor

```bash
docker-compose logs --tail=100 hbbs
docker-compose logs --tail=100 hbbr
```

### Comunidade RustDesk

- GitHub: https://github.com/rustdesk/rustdesk/issues
- Discord: https://discord.gg/rustdesk
- Reddit: r/rustdesk

## 📋 Checklist de Troubleshooting

Antes de pedir ajuda, verifique:

**Servidor:**
- [ ] Containers rodando (`docker-compose ps`)
- [ ] Portas abertas no firewall
- [ ] DNS aponta para o servidor
- [ ] Certificado SSL válido
- [ ] Logs sem erros críticos
- [ ] Recursos suficientes (CPU, RAM, Disco)

**Cliente:**
- [ ] RustDesk2.toml no lugar correto
- [ ] Chave pública correta
- [ ] Firewall Windows permite RustDesk
- [ ] Internet funcionando
- [ ] Executado como Administrador (para instalação)

## 🆘 Último Recurso

Se nada funcionar:

```bash
# Reset completo
cd /opt/zap-remote/server
docker-compose down -v
rm -rf data/*
docker-compose up -d

# Aguardar 10 segundos
sleep 10

# Obter nova chave
/opt/zap-remote/scripts/get-public-key.sh

# Atualizar cliente
/opt/zap-remote/scripts/update-client-key.sh
```

---

**Não resolveu?** Entre em contato: suporte@zapprovedor.com.br

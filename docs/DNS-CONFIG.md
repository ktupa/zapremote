# Configuração de DNS para ZAP Remote

Guia completo para configurar o DNS do domínio remote.zapprovedor.com.br

## 📋 Pré-requisitos

- Domínio `zapprovedor.com.br` registrado
- Acesso ao painel de controle do DNS
- IP público do servidor VPS

## 🌐 Descobrir IP do Servidor

```bash
# No servidor
curl ifconfig.me
# ou
curl ipinfo.io/ip
# ou
dig +short myip.opendns.com @resolver1.opendns.com
```

Anote este IP: `__________________`

## ⚙️ Configurar Registro DNS

### Opção 1: Registro A (Recomendado)

No painel de DNS do seu provedor, adicione:

```
Tipo: A
Nome: remote
Valor: SEU_IP_PUBLICO
TTL: 3600 (1 hora)
```

**Exemplo:**
```
Tipo: A
Nome: remote
Valor: 203.0.113.42
TTL: 3600
```

### Opção 2: Subdomínio CNAME

Se houver um domínio principal já configurado:

```
Tipo: CNAME
Nome: remote
Valor: servidor.principal.com.br
TTL: 3600
```

## 🏢 Configuração por Provedor

### Registro.br / Locaweb

1. Acesse o painel de controle
2. Menu: **Domínios** → **Gerenciar DNS**
3. Clique em **Adicionar Registro**
4. Selecione tipo **A**
5. **Nome**: `remote`
6. **Endereço IPv4**: Seu IP público
7. **TTL**: `3600`
8. Salvar

### GoDaddy

1. Acesse DNS Management
2. Clique em **Add**
3. **Type**: A
4. **Name**: remote
5. **Value**: Seu IP
6. **TTL**: 1 Hour
7. Save

### Cloudflare

1. Acesse o Dashboard
2. Selecione o domínio
3. Vá em **DNS**
4. **Add record**
5. **Type**: A
6. **Name**: remote
7. **IPv4 address**: Seu IP
8. **Proxy status**: DNS only (⚠️ Importante: desabilitar proxy)
9. **TTL**: Auto
10. Save

⚠️ **Importante no Cloudflare**: Desabilite o proxy (nuvem laranja) para RustDesk funcionar!

### Hostinger

1. Acesse hPanel
2. **Domínios** → Gerenciar
3. **DNS / Nameservers** → **DNS Zone Editor**
4. **Add Record**
5. Tipo: **A**
6. Nome: **remote**
7. Aponta para: Seu IP
8. TTL: **14400**
9. Adicionar

### HostGator

1. cPanel → **Zona DNS**
2. **Adicionar Registro A**
3. Nome: `remote`
4. Aponta para: Seu IP
5. TTL: `14400`
6. Adicionar

## ✅ Verificar Configuração

### Teste 1: Resolução DNS

```bash
# Linux/Mac
nslookup remote.zapprovedor.com.br

# ou
dig remote.zapprovedor.com.br

# ou
host remote.zapprovedor.com.br
```

**Resposta esperada:**
```
remote.zapprovedor.com.br has address 203.0.113.42
```

### Teste 2: DNS Público

```bash
# Testar com DNS do Google
nslookup remote.zapprovedor.com.br 8.8.8.8

# Testar com DNS da Cloudflare
nslookup remote.zapprovedor.com.br 1.1.1.1
```

### Teste 3: Propagação

Verifique propagação mundial:
- https://dnschecker.org
- https://www.whatsmydns.net

Procure por: `remote.zapprovedor.com.br`

## ⏱️ Tempo de Propagação

| TTL Configurado | Tempo Mínimo | Tempo Máximo |
|-----------------|--------------|--------------|
| 300 (5 min) | 5 minutos | 2 horas |
| 3600 (1 hora) | 1 hora | 24 horas |
| 86400 (1 dia) | 24 horas | 48 horas |

**Recomendado**: Use TTL de 3600 (1 hora) para equilíbrio entre cache e flexibilidade.

## 🔧 Configuração Avançada

### Registro CAA (Certificado SSL)

Para Let's Encrypt, adicione (opcional):

```
Tipo: CAA
Nome: remote
Valor: 0 issue "letsencrypt.org"
TTL: 3600
```

### Múltiplos Servidores (Load Balance)

Se tiver múltiplos servidores:

```
Tipo: A
Nome: remote
Valor: 203.0.113.42
TTL: 300

Tipo: A
Nome: remote
Valor: 203.0.113.43
TTL: 300
```

### IPv6 (Opcional)

Se o servidor tiver IPv6:

```
Tipo: AAAA
Nome: remote
Valor: 2001:db8::1
TTL: 3600
```

## 🐛 Problemas Comuns

### 1. DNS não resolve

**Causas:**
- Registro mal configurado
- Propagação ainda não completada
- Cache DNS local antigo

**Soluções:**
```bash
# Limpar cache DNS (Linux)
sudo systemd-resolve --flush-caches

# Limpar cache DNS (Windows)
ipconfig /flushdns

# Limpar cache DNS (Mac)
sudo dscacheutil -flushcache

# Aguardar propagação
# Usar IP temporariamente no RustDesk2.toml
```

### 2. Resolve em alguns lugares, outros não

**Causa:** Propagação em andamento

**Solução:** Aguardar 24-48 horas

### 3. SSL não funciona após configurar DNS

**Causa:** Certbot não conseguiu validar domínio

**Solução:**
```bash
# Reobter certificado
sudo certbot --nginx -d remote.zapprovedor.com.br --force-renewal

# Verificar logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### 4. Erro "NXDOMAIN"

**Causa:** Domínio não existe ou registro errado

**Solução:**
- Verificar nome do registro (deve ser exatamente "remote")
- Verificar domínio principal está funcionando
- Aguardar propagação

## 📝 Template de Configuração

```
=== Configuração DNS ZAP Remote ===

Domínio Principal: zapprovedor.com.br
Subdomínio: remote.zapprovedor.com.br
IP do Servidor: ___________________
Provedor DNS: _____________________

Registro DNS:
- Tipo: A
- Nome: remote
- Valor: [IP_DO_SERVIDOR]
- TTL: 3600

Status:
- [ ] DNS configurado
- [ ] Propagação verificada
- [ ] Funcionando em nslookup
- [ ] Funcionando em dnschecker.org
- [ ] SSL configurado
- [ ] RustDesk conectando
```

## 🔒 DNS e SSL

Sequência correta:

1. ✅ Configurar registro DNS
2. ⏱️ Aguardar propagação (1-24h)
3. ✔️ Verificar resolução com `nslookup`
4. 🔐 Executar `deploy-server.sh` para obter SSL
5. ✅ SSL será obtido automaticamente

## 📞 Suporte DNS por Provedor

| Provedor | Suporte | URL |
|----------|---------|-----|
| Registro.br | https://registro.br/ajuda | https://registro.br |
| Locaweb | 4003-0500 | https://locaweb.com.br |
| GoDaddy | +55 11 3957-5071 | https://godaddy.com |
| Cloudflare | Community | https://community.cloudflare.com |
| Hostinger | Chat Online | https://hostinger.com.br |
| HostGator | +55 11 4700-5555 | https://hostgator.com.br |

## 🎯 Checklist Final

Antes de executar `deploy-server.sh`:

- [ ] Registro DNS tipo A criado
- [ ] Nome: `remote`
- [ ] Valor: IP correto do servidor
- [ ] TTL: 3600 ou menor
- [ ] `nslookup remote.zapprovedor.com.br` retorna IP correto
- [ ] Verificado em https://dnschecker.org
- [ ] Aguardado pelo menos 1 hora após configuração

## 💡 Dicas

1. **Configurar antes do deploy**: Configure DNS com antecedência (24h antes)
2. **Testar antes**: Use `nslookup` antes de pedir SSL
3. **TTL baixo**: Use TTL de 300 durante testes, depois aumente para 3600
4. **Backup**: Anote a configuração antiga antes de modificar
5. **Staging**: Teste com um subdomínio de teste primeiro

## 📧 Próximos Passos

Após DNS configurado e funcionando:

1. Execute `/opt/zap-remote/scripts/deploy-server.sh`
2. O script obterá automaticamente o certificado SSL
3. Servidor ficará acessível via `remote.zapprovedor.com.br`

---

**Dúvidas?** Consulte: [Troubleshooting](TROUBLESHOOTING.md)

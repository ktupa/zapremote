# Guia de Compilação do Instalador Windows

Este guia explica como compilar o instalador personalizado do ZAP Remote para Windows.

## 📋 Pré-requisitos

### Ferramentas Necessárias

1. **Inno Setup 6** (ou superior)
   - Download: https://jrsoftware.org/isdl.php
   - Instale a versão completa

2. **RustDesk Cliente Windows**
   - Download: https://github.com/rustdesk/rustdesk/releases
   - Baixe a versão `rustdesk-<version>-x86_64.exe`

3. **Arquivo RustDesk2.toml**
   - Já configurado em `/opt/zap-remote/client/RustDesk2.toml`
   - Com a chave pública do servidor atualizada

## 🔧 Preparação

### 1. Criar Pasta de Build

No Windows, crie a estrutura:

```
C:\ZAPRemote-Build\
├── rustdesk.exe          (renomeie o executável baixado)
├── RustDesk2.toml        (copie do servidor)
├── ZAPRemote-Setup.iss   (copie do servidor)
├── icon.ico              (ícone do aplicativo)
├── license.txt           (licença do software)
└── output\               (será criado automaticamente)
```

### 2. Baixar RustDesk

```powershell
# No PowerShell
$url = "https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-x86_64.exe"
Invoke-WebRequest -Uri $url -OutFile "C:\ZAPRemote-Build\rustdesk.exe"
```

### 3. Copiar Arquivos do Servidor

Do servidor Linux, copie via SCP:

```bash
# No servidor
scp /opt/zap-remote/client/RustDesk2.toml usuario@windows-pc:C:/ZAPRemote-Build/
scp /opt/zap-remote/installer/ZAPRemote-Setup.iss usuario@windows-pc:C:/ZAPRemote-Build/
```

Ou baixe manualmente os arquivos.

### 4. Criar Ícone

Você pode:
- Usar um gerador online: https://convertico.com/
- Contratar um designer
- Usar o ícone padrão do RustDesk temporariamente

Salve como `icon.ico` na pasta de build.

### 5. Criar Licença

Crie `license.txt`:

```
Termos de Uso - ZAP Remote

Este software é fornecido pela ZAP Provedor para uso exclusivo 
de clientes autorizados. O uso não autorizado é proibido.

Baseado em RustDesk (https://rustdesk.com)
Licença: AGPLv3

© 2026 ZAP Provedor
Todos os direitos reservados.
```

## 🏗️ Compilação

### Opção 0: Build do source rebrandizado via GitHub Actions

Se o objetivo for gerar um `rustdesk.exe` realmente recompilado a partir de `rustdesk-source/`, o caminho mais curto a partir deste servidor Linux é usar um runner Windows no GitHub Actions.

Arquivos já preparados no projeto:

- `rustdesk-source/.github/workflows/zap-remote-windows.yml`
- `scripts/package-windows-installer.sh`

Fluxo:

1. Faça fork de `rustdesk-source` para uma conta sua no GitHub.
2. Envie as mudanças de branding para esse fork.
3. Execute manualmente o workflow `ZAP Remote Windows Build` na aba Actions.
4. Baixe o artefato Windows gerado pelo workflow.
5. Extraia o `rustdesk.exe` recompilado.
6. No servidor, gere um novo instalador com:

```bash
/opt/zap-remote/scripts/package-windows-installer.sh /caminho/para/rustdesk.exe ZAPRemote-Setup-v3.exe 3.0.0
```

7. Publique o instalador gerado em `/var/www/zap-remote/download/`.

### Opção 1: Interface Gráfica

1. Abra o Inno Setup
2. File → Open → Selecione `ZAPRemote-Setup.iss`
3. Build → Compile
4. Aguarde a compilação (alguns segundos)
5. O instalador estará em `output\ZAPRemote-Setup.exe`

### Opção 2: Linha de Comando

```batch
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "C:\ZAPRemote-Build\ZAPRemote-Setup.iss"
```

## ✅ Teste do Instalador

### Teste em VM

Recomendado testar em uma máquina virtual limpa:

1. Crie uma VM Windows 10/11
2. Instale o ZAPRemote-Setup.exe
3. Verifique se:
   - O aplicativo inicia corretamente
   - Conecta ao servidor `remote.zapprovedor.com.br`
   - Atalho no desktop foi criado
   - Serviço foi instalado (opcional)

### Verificar Configuração

Após instalar, verifique o arquivo:
```
%APPDATA%\RustDesk\config\RustDesk2.toml
```

Deve conter:
```toml
rendezvous_server = "remote.zapprovedor.com.br"
[options]
relay-server = "remote.zapprovedor.com.br"
key = "SUA_CHAVE_PUBLICA_AQUI"
```

## 📦 Distribuição

### Hospedar no Servidor Web

```bash
# Copie o instalador para o servidor
scp ZAPRemote-Setup.exe root@seu-servidor:/var/www/html/downloads/

# Configure permissões
chmod 644 /var/www/html/downloads/ZAPRemote-Setup.exe
```

Acesse via:
```
https://zapprovedor.com.br/downloads/ZAPRemote-Setup.exe
```

### Enviar para Clientes

- Por email
- Link de download
- Pen drive
- Compartilhamento de rede

## 🔄 Atualização

Quando atualizar a chave do servidor ou configuração:

1. Atualize `RustDesk2.toml` no servidor
2. Execute: `/opt/zap-remote/scripts/update-client-key.sh`
3. Copie o novo `RustDesk2.toml` para a pasta de build
4. Recompile o instalador
5. Distribua a nova versão

## 🐛 Solução de Problemas

### Erro: "Cannot open file"

Certifique-se de que todos os arquivos estão na pasta correta:
- `rustdesk.exe`
- `RustDesk2.toml`
- `icon.ico`

### Instalador não conecta ao servidor

1. Verifique se a chave no `RustDesk2.toml` está correta
2. Teste conexão: `telnet remote.zapprovedor.com.br 21115`
3. Confira DNS e firewall

### Ícone não aparece

Certifique-se de que `icon.ico` é um arquivo .ICO válido (não PNG ou JPG renomeado)

## 📝 Checklist de Build

- [ ] RustDesk baixado e renomeado para `rustdesk.exe`
- [ ] RustDesk2.toml com chave pública atualizada
- [ ] Ícone `icon.ico` criado
- [ ] Licença `license.txt` criada
- [ ] Script `.iss` na pasta
- [ ] Inno Setup instalado
- [ ] Compilado sem erros
- [ ] Testado em VM
- [ ] Instalador funcionando corretamente

## 🎯 Resultado Final

Após a compilação, você terá:

**Arquivo**: `output\ZAPRemote-Setup.exe`  
**Tamanho**: ~25-30 MB  
**Silencioso**: Suporta instalação silenciosa com `/VERYSILENT /SUPPRESSMSGBOXES`

## 💡 Dicas

1. **Versionamento**: Atualize o número da versão em `ZAPRemote-Setup.iss`
2. **Assinatura Digital**: Considere assinar o executável com certificado de código
3. **Antivírus**: Alguns antivírus podem detectar como falso positivo inicialmente
4. **Testes**: Sempre teste antes de distribuir em massa

---

**Próximos passos**: [Solução de Problemas](TROUBLESHOOTING.md)

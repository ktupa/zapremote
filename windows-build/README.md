# Windows Build Handoff

Esta pasta foi preparada para levar ao Windows e gerar um novo instalador do ZAP Remote.

## O que colocar aqui no Windows

- `rustdesk.exe` recompilado a partir do source modificado
- `RustDesk2.toml` ja esta pronto
- `icon.ico` ja esta pronto
- `license.txt` ja esta pronto
- `ZAPRemote-v3.nsi` ja esta pronto
- `build-installer.ps1` ja esta pronto

## Estrutura esperada

```text
windows-build/
  rustdesk.exe
  RustDesk2.toml
  icon.ico
  license.txt
  ZAPRemote-v3.nsi
  build-installer.ps1
```

## Como gerar no Windows

1. Instale o NSIS.
2. Copie o `rustdesk.exe` recompilado para dentro desta pasta.
3. Abra PowerShell nesta pasta.
4. Execute:

```powershell
./build-installer.ps1
```

Se o NSIS estiver em outro caminho:

```powershell
./build-installer.ps1 -NsisExe "D:\Ferramentas\NSIS\makensis.exe"
```

## Saida esperada

- `ZAPRemote-Setup-v3.exe`

## Como subir para o servidor

Exemplo via SCP:

```bash
scp ZAPRemote-Setup-v3.exe root@remote.zapprovedor.com.br:/var/www/zap-remote/download/
```

Depois ajuste permissao no servidor:

```bash
chmod 644 /var/www/zap-remote/download/ZAPRemote-Setup-v3.exe
```

## Link final esperado

- `https://remote.zapprovedor.com.br/download/ZAPRemote-Setup-v3.exe`

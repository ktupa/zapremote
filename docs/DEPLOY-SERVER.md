# Guia de Deploy do Servidor

Guia objetivo para subir o servidor do ZAP Remote com os scripts deste repositório.

## Pré-requisitos

- Ubuntu 20.04+ ou Debian 11+
- Acesso root
- DNS do domínio apontando para o IP público do servidor
- Portas 80, 443 e 21115-21119 liberadas no provedor

## Variáveis opcionais

O script de deploy aceita estes parâmetros por variável de ambiente:

```bash
ZAP_DOMAIN=remote.zapprovedor.com.br
ZAP_CERTBOT_EMAIL=admin@zapprovedor.com.br
ZAP_JWT_KEY=$(openssl rand -hex 32)
```

Se você não definir `ZAP_JWT_KEY`, o deploy gera uma chave automaticamente.

## Passo a passo

```bash
cd /opt/zap-remote/scripts
./deploy-server.sh
```

O deploy faz o seguinte:

1. Atualiza o sistema e instala dependências
2. Instala Docker, Certbot, Nginx, SQLite e `python3-bcrypt`
3. Configura o firewall
4. Sobe um Nginx temporário em HTTP para o desafio do Let's Encrypt
5. Emite o certificado SSL
6. Ativa a configuração HTTPS definitiva
7. Gera `jwt.key` se necessário
8. Inicia os containers do RustDesk
9. Atualiza a chave pública nos arquivos de configuração do cliente

## Observação importante sobre mobile

Clientes móveis dependem de WSS publicado pelo Nginx neste ambiente.

Além do site e da API, o vhost precisa encaminhar:

- `/ws/id` para `127.0.0.1:21118/`
- `/ws/relay` para `127.0.0.1:21119/`

Se esses caminhos não existirem, ou se o `proxy_pass` repassar `/ws/id` e `/ws/relay` sem a barra final, é comum o desktop continuar funcionando e o celular falhar.

## Pós-deploy

Verifique o estado do ambiente:

```bash
/opt/zap-remote/scripts/manage-server.sh status
/opt/zap-remote/scripts/diagnose.sh
/opt/zap-remote/scripts/get-public-key.sh
```

Se precisar sincronizar novamente a chave pública:

```bash
/opt/zap-remote/scripts/update-client-key.sh
```

## Gerenciamento de usuários

O script de usuários usa a API local em `127.0.0.1:21114`.

Se a senha administrativa não estiver no log da API, informe-a manualmente:

```bash
export ZAP_ADMIN_PASS='sua-senha-admin'
/opt/zap-remote/scripts/manage-users.sh listar
```

## Diagnóstico

Em caso de falha no deploy:

```bash
/opt/zap-remote/scripts/diagnose.sh
tail -n 50 /opt/zap-remote/server/api-data/runtime/log.txt
```

Para procedimentos adicionais, consulte `docs/TROUBLESHOOTING.md`.
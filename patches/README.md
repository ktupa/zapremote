# RustDesk Source Patch

Este projeto raiz nao versiona a pasta `rustdesk-source/` diretamente porque ela e um repositorio Git separado do upstream.

As customizacoes locais do cliente foram exportadas para um patch nesta pasta.

Arquivo principal:

- `rustdesk-source-zapremote.patch`

Para reaplicar em outro local, use:

```bash
/opt/zap-remote/scripts/apply-rustdesk-patch.sh /caminho/do/destino
```

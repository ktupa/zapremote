; ZAP Remote - Instalador NSIS
; Acesso remoto seguro por ZAP Provedor

!include "MUI2.nsh"
!include "FileFunc.nsh"

; =================== DEFINIÇÕES ===================
!define PRODUCT_NAME "ZAP Remote"
!define PRODUCT_VERSION "1.0.1"
!define PRODUCT_PUBLISHER "ZAP Provedor"
!define PRODUCT_WEB_SITE "https://remote.zapprovedor.com.br"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\rustdesk.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; Nome personalizado para a interface do RustDesk
!define APP_DISPLAY_NAME "ZAP Remote"

; =================== CONFIGURAÇÕES ===================
SetCompressor /SOLID lzma
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "ZAPRemote-Setup.exe"
InstallDir "$PROGRAMFILES64\${PRODUCT_NAME}"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show
RequestExecutionLevel admin

; =================== INTERFACE ===================
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Bem-vindo ao ${PRODUCT_NAME}"
!define MUI_WELCOMEPAGE_TEXT "Este assistente irá instalar o ${PRODUCT_NAME} ${PRODUCT_VERSION} no seu computador.$\r$\n$\r$\nO ${PRODUCT_NAME} permite acesso remoto seguro e rápido aos seus dispositivos.$\r$\n$\r$\nDesenvolvido por ${PRODUCT_PUBLISHER}.$\r$\n$\r$\nClique em Avançar para continuar."
!define MUI_FINISHPAGE_RUN "$INSTDIR\rustdesk.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Iniciar ${PRODUCT_NAME}"
!define MUI_FINISHPAGE_LINK "Visite remote.zapprovedor.com.br"
!define MUI_FINISHPAGE_LINK_LOCATION "https://remote.zapprovedor.com.br"

; =================== PÁGINAS ===================
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_INSTFILES

; =================== IDIOMA ===================
!insertmacro MUI_LANGUAGE "PortugueseBR"

; =================== SEÇÃO PRINCIPAL ===================
Section "Instalação Principal" SEC01
    SetOutPath "$INSTDIR"
    SetOverwrite on

    ; Copiar executável
    File "rustdesk.exe"

    ; ========================================
    ; BRANDING: Variável de ambiente para nome customizado na UI
    ; O RustDesk lê RUSTDESK_APPNAME para exibir "ZAP Remote"
    ; ========================================
    DetailPrint "Configurando ${APP_DISPLAY_NAME}..."
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "RUSTDESK_APPNAME" "${APP_DISPLAY_NAME}"

    ; Notificar Windows da mudança
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000

    ; Criar diretório de configuração
    CreateDirectory "$APPDATA\RustDesk\config"

    ; Copiar configuração pré-definida
    SetOutPath "$APPDATA\RustDesk\config"
    File "RustDesk2.toml"

    ; Voltar para dir de instalação
    SetOutPath "$INSTDIR"

    ; Criar atalhos no Menu Iniciar
    CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\rustdesk.exe" "" "$INSTDIR\rustdesk.exe" 0
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\Desinstalar ${PRODUCT_NAME}.lnk" "$INSTDIR\uninst.exe"

    ; Criar atalho no Desktop
    CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\rustdesk.exe" "" "$INSTDIR\rustdesk.exe" 0

    ; Registrar no Windows (Add/Remove Programs mostra "ZAP Remote")
    WriteUninstaller "$INSTDIR\uninst.exe"
    WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\rustdesk.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\rustdesk.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "HelpLink" "${PRODUCT_WEB_SITE}"

    ; Calcular tamanho para Add/Remove Programs
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"

    ; Instalar serviço
    DetailPrint "Instalando serviço ${PRODUCT_NAME}..."
    nsExec::ExecToLog '"$INSTDIR\rustdesk.exe" --install-service'
SectionEnd

; =================== SEÇÃO DE AUTOSTART ===================
Section "Iniciar com Windows" SEC02
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "${PRODUCT_NAME}" '"$INSTDIR\rustdesk.exe" --tray'
SectionEnd

; =================== DESINSTALADOR ===================
Section Uninstall
    ; Parar serviço
    nsExec::ExecToLog '"$INSTDIR\rustdesk.exe" --uninstall-service'

    ; Remover variável de ambiente RUSTDESK_APPNAME
    DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "RUSTDESK_APPNAME"
    SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0 "STR:Environment" /TIMEOUT=5000

    ; Remover registro de autostart
    DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "${PRODUCT_NAME}"

    ; Remover atalhos
    Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
    RMDir /r "$SMPROGRAMS\${PRODUCT_NAME}"

    ; Remover arquivos
    Delete "$INSTDIR\rustdesk.exe"
    Delete "$INSTDIR\uninst.exe"
    RMDir "$INSTDIR"

    ; Remover registros
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"

    SetAutoClose true
SectionEnd

; Script de Instalação do ZAP Remote
; Baseado em RustDesk com configuração automática
; Criado para ZAP Provedor

#define MyAppName "ZAP Remote"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "ZAP Provedor"
#define MyAppURL "https://zapprovedor.com.br"
#define MyAppExeName "rustdesk.exe"

[Setup]
; Identificação do aplicativo
AppId={{8D9F2E15-6A7C-4B3D-9E1F-4C5B6A7D8E9F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Configurações de instalação
DefaultDirName={commonpf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=ZAPRemote-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Privilégios e compatibilidade
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

; Visual
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "portuguesebr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "autostart"; Description: "Iniciar automaticamente com o Windows"; GroupDescription: "Opções adicionais:"; Flags: checked

[Files]
; Executável principal do RustDesk
Source: "rustdesk.exe"; DestDir: "{app}"; Flags: ignoreversion
; Arquivo de configuração
Source: "RustDesk2.toml"; DestDir: "{userappdata}\RustDesk\config"; Flags: ignoreversion
; DLLs e dependências
Source: "*.dll"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Ícone e recursos
Source: "icon.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Configurar inicialização automática se selecionado
Filename: "{app}\{#MyAppExeName}"; Parameters: "--install-service"; Flags: runhidden waituntilterminated; Tasks: autostart
; Executar após instalação
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; Parar serviço antes de desinstalar
Filename: "{app}\{#MyAppExeName}"; Parameters: "--uninstall-service"; Flags: runhidden waituntilterminated

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
  if RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8D9F2E15-6A7C-4B3D-9E1F-4C5B6A7D8E9F}_is1') then
  begin
    if MsgBox('ZAP Remote já está instalado. Deseja atualizar?', mbConfirmation, MB_YESNO) = IDYES then
      Result := True
    else
      Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigDir: string;
begin
  if CurStep = ssPostInstall then
  begin
    ConfigDir := ExpandConstant('{userappdata}\RustDesk\config');
    if not DirExists(ConfigDir) then
      CreateDir(ConfigDir);
    Log('Configuração instalada com sucesso em: ' + ConfigDir);
  end;
end;

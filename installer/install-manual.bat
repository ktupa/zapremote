@echo off
:: Script de Instalação Manual do ZAP Remote
:: Para Windows 10/11

echo ========================================
echo ZAP Remote - Instalação Manual
echo ========================================
echo.

:: Verificar privilégios de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERRO: Este script precisa ser executado como Administrador!
    echo Clique com botao direito e selecione "Executar como administrador"
    pause
    exit /b 1
)

echo [1/4] Criando diretórios...
if not exist "%ProgramFiles%\ZAP Remote" mkdir "%ProgramFiles%\ZAP Remote"
if not exist "%APPDATA%\RustDesk\config" mkdir "%APPDATA%\RustDesk\config"

echo [2/4] Copiando arquivos...
copy /Y "rustdesk.exe" "%ProgramFiles%\ZAP Remote\"
copy /Y "*.dll" "%ProgramFiles%\ZAP Remote\" 2>nul
copy /Y "RustDesk2.toml" "%APPDATA%\RustDesk\config\"

echo [3/4] Criando atalhos...
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%Public%\Desktop\ZAP Remote.lnk'); $Shortcut.TargetPath = '%ProgramFiles%\ZAP Remote\rustdesk.exe'; $Shortcut.Save()"

echo [4/4] Configurando inicialização automática...
"%ProgramFiles%\ZAP Remote\rustdesk.exe" --install-service

echo.
echo ========================================
echo Instalação concluída com sucesso!
echo ========================================
echo.
echo Iniciando ZAP Remote...
start "" "%ProgramFiles%\ZAP Remote\rustdesk.exe"

pause

@echo off
chcp 65001 >nul
echo ========================================
echo  Movendo google-services.json
echo ========================================
echo.

REM Verificar se o arquivo existe na raiz
if not exist "google-services.json" (
    echo ❌ Arquivo google-services.json não encontrado na raiz do projeto!
    echo.
    echo Por favor, coloque o arquivo google-services.json na pasta:
    echo   %CD%
    echo.
    pause
    exit /b 1
)

echo ✅ Arquivo encontrado!
echo.

REM Criar diretório android\app se não existir
if not exist "android\app" (
    echo Criando diretório android\app...
    mkdir "android\app" 2>nul
)

REM Copiar arquivo
echo Copiando google-services.json para android\app\...
copy "google-services.json" "android\app\google-services.json" >nul

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  ✅ Arquivo movido com sucesso!
    echo ========================================
    echo.
    echo Arquivo copiado para: android\app\google-services.json
    echo.
    echo Próximos passos:
    echo 1. ✅ Firebase já está configurado no código
    echo 2. Ative Google Sign-In no Firebase Console
    echo 3. Teste: flutter run
    echo.
) else (
    echo.
    echo ❌ Erro ao copiar arquivo!
    echo.
    pause
    exit /b 1
)

pause


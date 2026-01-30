@echo off
chcp 65001 > nul
setlocal EnableExtensions EnableDelayedExpansion

echo ====================================
echo  COMPILAR APK - SafePlate MVP
echo ====================================
echo.

echo Escolha uma opcao:
echo.
echo 1. APK Debug (Desenvolvimento)
echo 2. APK Release (Producao)
echo 3. APK Split por ABI
echo 4. Compilar e Instalar via USB
echo 5. Sair
echo.

set /p escolha=Digite o numero da opcao (1-5): 

if "%escolha%"=="1" (
    echo.
    echo Compilando APK Debug...
    flutter build apk --debug
    if errorlevel 1 (
        echo Erro ao compilar APK Debug!
    ) else (
        echo APK Debug compilado com sucesso!
        echo build\app\outputs\flutter-apk\app-debug.apk
    )
)

if "%escolha%"=="2" (
    echo.
    echo Compilando APK Release...
    flutter build apk --release
    if errorlevel 1 (
        echo Erro ao compilar APK Release!
    ) else (
        echo APK Release compilado com sucesso!
        echo build\app\outputs\flutter-apk\app-release.apk
    )
)

if "%escolha%"=="3" (
    echo.
    echo Compilando APK Split por ABI...
    flutter build apk --split-per-abi --release
    if errorlevel 1 (
        echo Erro ao compilar APK Split!
    ) else (
        echo APKs gerados com sucesso!
        echo arm64-v8a = recomendado para celulares modernos
    )
)

if "%escolha%"=="4" (
    echo.
    echo Verificando dispositivos...
    flutter devices

    echo.
    echo Compilando APK Release...
    flutter build apk --release
    if errorlevel 1 (
        echo Erro ao compilar APK!
    ) else (
        echo Instalando no dispositivo...
        flutter install
        if errorlevel 1 (
            echo Falha ao instalar no dispositivo.
        ) else (
            echo APK instalado com sucesso!
        )
    )
)

if "%escolha%"=="5" (
    echo Saindo...
    exit /b 0
)

echo.
pause

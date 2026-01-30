@echo off
chcp 65001 > nul
echo ====================================
echo  ACEITAR LICENÇAS ANDROID
echo ====================================
echo.
echo Isso vai aceitar todas as licenças Android necessárias.
echo Digite 'y' para cada licença e pressione Enter.
echo.
echo Pressione qualquer tecla para continuar...
pause > nul
echo.
flutter doctor --android-licenses
echo.
echo ✅ Licenças aceitas!
echo.
pause


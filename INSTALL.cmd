@echo off
setlocal
chcp 65001 >nul
title RX-78-2 Codex Skin Installer
echo.
echo ========================================
echo   RX-78-2 WHITE BASE - Codex Gundam Skin
echo ========================================
echo.
echo Installing. Please do not close this window.
echo Codex will restart once during installation.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Skin.ps1" -SourceRoot "%~dp0"
set "INSTALL_EXIT=%ERRORLEVEL%"
echo.
if "%INSTALL_EXIT%"=="0" (
  echo [OK] Skin installed and verified.
  echo You can delete this extracted folder now.
) else (
  echo [FAILED] Installation error code: %INSTALL_EXIT%
  echo Keep the error text shown above for troubleshooting.
)
echo.
pause
exit /b %INSTALL_EXIT%

@echo off
setlocal
chcp 65001 >nul
title RX-78-2 Codex Skin Uninstaller
echo.
echo Removing the Gundam skin and restoring normal Codex startup...
echo.
set "UNINSTALLER=%LOCALAPPDATA%\CodexDreamSkinGundam\skin\Uninstall-Skin.ps1"
if exist "%UNINSTALLER%" (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%UNINSTALLER%"
) else (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall-Skin.ps1"
)
set "UNINSTALL_EXIT=%ERRORLEVEL%"
echo.
if "%UNINSTALL_EXIT%"=="0" (
  echo [OK] Skin removed. Codex is back to normal startup.
) else (
  echo [FAILED] Uninstall error code: %UNINSTALL_EXIT%
)
echo.
pause
exit /b %UNINSTALL_EXIT%

@echo off
chcp 65001 >nul
echo Installing and starting the Hermes Telegram team inside WSL...
wsl --cd "%~dp0.." -- bash scripts/bootstrap.sh
pause

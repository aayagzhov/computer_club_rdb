@echo off

echo.
echo ============================================
echo  Start docker containers
echo ============================================

docker compose up -d

echo.
echo === Waiting for all containers to be ready (30 seconds) ===
timeout /t 30 /nobreak > nul

init.bat

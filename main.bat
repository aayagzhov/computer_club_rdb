@echo off
docker compose up -d


echo Waiting for containers to start...
:wait_loop
docker inspect -f "{{.State.Running}}" central_db | findstr true >nul
if errorlevel 1 (
    echo central_db not ready yet, waiting 5 seconds...
    timeout /t 5 >nul
    goto wait_loop
)
echo Containers are up!

.\scripts\init.bat

echo Initialization complete.
pause
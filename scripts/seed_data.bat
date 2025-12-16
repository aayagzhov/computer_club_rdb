@echo off
echo ============================================
echo  Seed data
echo ============================================

docker exec central_db bash -c "psql -U admin -d computer_club_rdb -f /seed/1_init_nsi.sql"

echo.
echo === Waiting for all nodes to be ready (5 seconds) ===
timeout /t 5 /nobreak > nul

set CONTAINERS=central_db club1_db club2_db club3_db

for %%C in (%CONTAINERS%) do (
    echo === Setting up %%C ===
    docker exec %%C bash -c "psql -U admin  -d computer_club_rdb -f /seed/2_seed_data.sql"
)

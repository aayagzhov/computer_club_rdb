@echo off
set CONTAINERS=central_db club1_db club2_db club3_db

echo ============================================
echo  Init data bases
echo ============================================

echo ============================================
echo  STAGE 1: Creating schema and Spock nodes
echo ============================================

for %%C in (%CONTAINERS%) do (
    echo === Setting up %%C ===
    docker exec %%C bash -c "psql -U pgedge -d postgres          -f /general/1_init.sql"
    docker exec %%C bash -c "psql -U admin  -d computer_club_rdb -f /general/2_shema.sql"
    docker exec %%C bash -c "psql -U admin  -d computer_club_rdb -f /general/3_triggers.sql"
    docker exec %%C bash -c "psql -U admin  -d computer_club_rdb -f /settings/1_sequences.sql"
    docker exec %%C bash -c "psql -U admin  -d computer_club_rdb -f /settings/2_publications.sql"
    docker exec %%C bash -c "psql -U admin  -d computer_club_rdb -f /settings/3_create_spok_node.sql"
)

echo.
echo === Waiting for all nodes to be ready (10 seconds) ===
timeout /t 10 /nobreak > nul

echo.
echo ============================================
echo  STAGE 2: Creating subscriptions
echo ============================================

for %%C in (%CONTAINERS%) do (
    echo === Creating subscriptions on %%C ===
    docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /settings/4_create_subscriptions.sql"
)

echo.
echo ============================================
echo  Master-Master replication setup complete!
echo ============================================

pause

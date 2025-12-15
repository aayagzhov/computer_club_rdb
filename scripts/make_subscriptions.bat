@echo off
set CONTAINERS=club1_db

for %%C in (%CONTAINERS%) do (
    echo === Updating %%C ===
    docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /settings/4_create_subscriptions.sql"
)

echo Done.
pause

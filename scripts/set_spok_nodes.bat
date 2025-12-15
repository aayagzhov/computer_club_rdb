@echo off
set CONTAINERS=central_db club1_db club2_db club3_db

for %%C in (%CONTAINERS%) do (
    echo === Updating %%C ===
    docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /settings/3_create_spok_node.sql"
)

echo Done.
pause

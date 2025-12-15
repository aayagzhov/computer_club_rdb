@echo off
set CONTAINERS=central_db club1_db club2_db club3_db

for %%C in (%CONTAINERS%) do (
    echo === Updating %%C ===
    docker exec %%C bash -c "psql -U pgedge -d postgres -f /general/1_init.sql"
    docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /general/2_shema.sql"
    docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /settings/1_sequences.sql"
    docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /settings/3_create_spok_node.sql"
    @REM docker exec %%C bash -c "psql -U admin -d computer_club_rdb -f /settings/4_create_subscriptions.sql"
)

echo Done.

pause

#!/bin/bash

CONTAINERS="central_db club1_db club2_db club3_db"

for C in $CONTAINERS; do
    echo "=== Creating subscriptions on $C ==="
    docker exec $C bash -c "psql -U admin -d computer_club_rdb -f /settings/4_create_subscriptions.sql"
done

echo "Done."


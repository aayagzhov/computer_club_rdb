docker exec -i central_db psql -U admin -d computer_club_rdb -f ./settings/create_pqlogical_node.sql

docker exec -i club1_db psql -U admin -d computer_club_rdb -f ./settings/create_pqlogical_node.sql
docker exec -i club2_db psql -U admin -d computer_club_rdb -f ./settings/create_pqlogical_node.sql
docker exec -i club3_db psql -U admin -d computer_club_rdb -f ./settings/create_pqlogical_node.sql
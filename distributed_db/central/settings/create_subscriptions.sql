-- Подписываемся на club1
CREATE SUBSCRIPTION sub_from_club1
  CONNECTION 'host=club1_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION club_local_pub;

-- Подписываемся на club2
CREATE SUBSCRIPTION sub_from_club2
  CONNECTION 'host=club2_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION club_local_pub;

-- Подписываемся на club3
CREATE SUBSCRIPTION sub_from_club3
  CONNECTION 'host=club3_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION club_local_pub;

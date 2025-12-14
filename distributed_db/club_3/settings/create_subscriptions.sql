
CREATE SUBSCRIPTION sub_central_from_club3
  CONNECTION 'host=central_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION cental_pub
WITH (copy_data = true, create_slot = true);

SELECT pglogical.create_subscription(
    subscription_name := 'sub_club3_from_central',
    provider_dsn := 'host=central_db port=5432 dbname=computer_club_rdb user=admin password=password'
);

SELECT pglogical.create_subscription(
    subscription_name := 'sub_club3_from_club1',
    provider_dsn := 'host=club1_db port=5432 dbname=computer_club_rdb user=admin password=password'
);

SELECT pglogical.create_subscription(
    subscription_name := 'sub_club3_from_club2',
    provider_dsn := 'host=club2_db port=5432 dbname=computer_club_rdb user=admin password=password'
);

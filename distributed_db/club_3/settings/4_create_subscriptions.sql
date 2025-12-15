-- Subscribe club3 to central and other clubs for master-master replication on clients table

SELECT spock.sub_create(
    subscription_name := 'sub_from_central_to_club3_master_master',
    provider_dsn := 'host=central_db port=5432 user=admin password=password dbname=computer_club_rdb',
    replication_sets := ARRAY['central_master_master'],
    synchronize_structure := false,
    synchronize_data := false,
    forward_origins := ARRAY[]::text[]
);

SELECT spock.sub_create(
    subscription_name := 'sub_from_club1_to_club3_master_master',
    provider_dsn := 'host=club1_db port=5432 user=admin password=password dbname=computer_club_rdb',
    replication_sets := ARRAY['club1_master_master'],
    synchronize_structure := false,
    synchronize_data := false,
    forward_origins := ARRAY[]::text[]
);

SELECT spock.sub_create(
    subscription_name := 'sub_from_club2_to_club3_master_master',
    provider_dsn := 'host=club2_db port=5432 user=admin password=password dbname=computer_club_rdb',
    replication_sets := ARRAY['club2_master_master'],
    synchronize_structure := false,
    synchronize_data := false,
    forward_origins := ARRAY[]::text[]
);

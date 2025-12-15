CREATE SUBSCRIPTION sub_from_club1
  CONNECTION 'host=club1_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION clubs_consolidation;

CREATE SUBSCRIPTION sub_from_club2
  CONNECTION 'host=club2_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION clubs_consolidation;

CREATE SUBSCRIPTION sub_from_club3
  CONNECTION 'host=club3_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION clubs_consolidation;

SELECT spock.sub_create(
    subscription_name := 'sub_from_club1_to_center_master_master',
    provider_dsn := 'host=club1_db port=5432 user=admin password=password dbname=computer_club_rdb',
    replication_sets := ARRAY['club1_master_master'],
    synchronize_structure := false,
    synchronize_data := false,
    forward_origins := ARRAY[]::text[]
);

SELECT spock.sub_create(
    subscription_name := 'sub_from_club2_to_center_master_master',
    provider_dsn := 'host=club2_db port=5432 user=admin password=password dbname=computer_club_rdb',
    replication_sets := ARRAY['club2_master_master'],
    synchronize_structure := false,
    synchronize_data := false,
    forward_origins := ARRAY[]::text[]
);

SELECT spock.sub_create(
    subscription_name := 'sub_from_club3_to_center_master_master',
    provider_dsn := 'host=club3_db port=5432 user=admin password=password dbname=computer_club_rdb',
    replication_sets := ARRAY['club3_master_master'],
    synchronize_structure := false,
    synchronize_data := false,
    forward_origins := ARRAY[]::text[]
);

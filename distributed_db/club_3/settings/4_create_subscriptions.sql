SELECT spock.sub_create(
    'sub_from_central_master_master',
    'host=central_db port=5432 user=admin password=password dbname=computer_club_rdb',
    ARRAY['central_master_master'],
    true,
    true,
    ARRAY[]::text[]
);

SELECT spock.sub_create(
    'sub_from_club1_master_master',
    'host=club1_db port=5432 user=admin password=password dbname=computer_club_rdb',
    ARRAY['club1_master_master'],
    true,
    true,
    ARRAY[]::text[]
);

SELECT spock.sub_create(
    'sub_from_club2_master_master',
    'host=club2_db port=5432 user=admin password=password dbname=computer_club_rdb',
    ARRAY['club2_master_master'],
    true,
    true,
    ARRAY[]::text[]
);
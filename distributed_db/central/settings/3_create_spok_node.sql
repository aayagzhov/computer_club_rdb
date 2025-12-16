-- Create Spock node for central database
SELECT spock.node_create(
    node_name := 'central',
    dsn := 'host=central_db port=5432 dbname=computer_club_rdb user=admin password=password'
);

-- Create replication set for master-master replication
SELECT spock.repset_create(
    set_name := 'central_master_master',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := true
);

-- Add clients table to replication set
SELECT spock.repset_add_table(
    set_name := 'central_master_master',
    relation := 'public.clients',
    synchronize_data := false,
    columns := NULL,
    row_filter := NULL
);

-- Create separate replication sets for maintenance_requests per club
SELECT spock.repset_create(
    set_name := 'central_maintenance_club1',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := true
);

SELECT spock.repset_create(
    set_name := 'central_maintenance_club2',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := true
);

SELECT spock.repset_create(
    set_name := 'central_maintenance_club3',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := true
);

-- Add maintenance_requests with row filters for each club
SELECT spock.repset_add_table(
    set_name := 'central_maintenance_club1',
    relation := 'public.maintenance_requests',
    synchronize_data := false,
    columns := NULL,
    row_filter := 'club_id = 1'
);

SELECT spock.repset_add_table(
    set_name := 'central_maintenance_club2',
    relation := 'public.maintenance_requests',
    synchronize_data := false,
    columns := NULL,
    row_filter := 'club_id = 2'
);

SELECT spock.repset_add_table(
    set_name := 'central_maintenance_club3',
    relation := 'public.maintenance_requests',
    synchronize_data := false,
    columns := NULL,
    row_filter := 'club_id = 3'
);

-- Set conflict resolution strategy for master-master replication
-- Using 'last_update_wins' to resolve conflicts based on commit timestamp
-- DO $$
-- BEGIN
--     -- Try to set conflict resolution (Spock 5.x syntax)
--     PERFORM spock.alter_table_conflict_detection(
--         'public.clients',
--         'origin_wins'
--     );
-- EXCEPTION WHEN OTHERS THEN
--     RAISE NOTICE 'Conflict resolution setup skipped or using default';
-- END $$;

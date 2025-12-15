-- Create Spock node for club1 database
SELECT spock.node_create(
    node_name := 'club1',
    dsn := 'host=club1_db port=5432 dbname=computer_club_rdb user=admin password=password'
);

-- Create replication set for master-master replication
SELECT spock.repset_create(
    set_name := 'club1_master_master',
    replicate_insert := true,
    replicate_update := true,
    replicate_delete := true,
    replicate_truncate := true
);

-- Add clients table to replication set
SELECT spock.repset_add_table(
    set_name := 'club1_master_master',
    relation := 'public.clients',
    synchronize_data := false,
    columns := NULL,
    row_filter := NULL
);

-- Set conflict resolution strategy for master-master replication
-- Using 'last_update_wins' to resolve conflicts based on last_modified timestamp
DO $$
BEGIN
    PERFORM spock.alter_table_conflict_detection(
        'public.clients',
        'last_update_wins'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Conflict resolution setup skipped or using default';
END $$;

-- Установка session variable для идентификации узла (club1 = 1)
ALTER DATABASE computer_club_rdb SET app.current_club_id = '1';

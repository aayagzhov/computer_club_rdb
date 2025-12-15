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

-- Set conflict resolution strategy for master-master replication
-- Using 'last_update_wins' to resolve conflicts based on last_modified timestamp
DO $$
BEGIN
    -- Try to set conflict resolution (Spock 5.x syntax)
    -- last_update_wins использует поле last_modified для разрешения конфликтов
    PERFORM spock.alter_table_conflict_detection(
        'public.clients',
        'last_update_wins'
    );
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Conflict resolution setup skipped or using default';
END $$;

-- Установка session variable для идентификации узла (центральный офис = 0)
ALTER DATABASE computer_club_rdb SET app.current_club_id = '0';

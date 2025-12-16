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

SELECT pglogical.create_node(
    node_name := 'central',
    dsn := 'host=central_db port=5432 dbname=computer_club_rdb user=admin password=password'
);
SELECT pglogical.replication_set_add_table('default', 'clients', true);
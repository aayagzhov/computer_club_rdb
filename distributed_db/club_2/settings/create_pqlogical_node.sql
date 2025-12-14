REVOKE ALL PRIVILEGES ON TABLE tariffs, configurations, gaming_seat_statuses,
  booking_statuses, discount_statuses, job_titles, employees, clubs
  FROM admin;

GRANT SELECT ON TABLE tariffs, configurations, gaming_seat_statuses,
  booking_statuses, discount_statuses, job_titles, employees, clubs
  TO admin;




SELECT pglogical.create_node(
    node_name := 'club2',
    dsn := 'host=club2_db port=5432 dbname=computer_club_rdb user=admin password=password'
);
SELECT pglogical.replication_set_add_table('default', 'clients', true);
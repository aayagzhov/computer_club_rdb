REVOKE ALL PRIVILEGES ON TABLE tariffs, configurations, gaming_seat_statuses,
  booking_statuses, discount_statuses, job_titles, employees, clubs
  FROM admin;

GRANT SELECT ON TABLE tariffs, configurations, gaming_seat_statuses,
  booking_statuses, discount_statuses, job_titles, employees, clubs
  TO admin;

CREATE SUBSCRIPTION sub_central_from_club3
  CONNECTION 'host=central_db port=5432 dbname=computer_club_rdb user=admin password=password'
  PUBLICATION cental_pub
WITH (copy_data = true, create_slot = true);
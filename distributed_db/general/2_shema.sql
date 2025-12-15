CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION spock;

CREATE TABLE IF NOT EXISTS tariffs(
  id smallserial PRIMARY KEY,
  name text NOT NULL,
  price smallint NOT NULL,
  description text NOT NULL
);
COMMENT ON COLUMN tariffs.price IS 'price for one hour';

CREATE TABLE IF NOT EXISTS configurations(
  id serial PRIMARY KEY,
  tariff_id smallint NOT NULL,
  cpu text NOT NULL,
  gpu text NOT NULL,
  ram text NOT NULL,
  storage text NOT NULL,
  display text NOT NULL,
  mouse text NOT NULL,
  keyboard text NOT NULL,
  headset text NOT NULL,
  os text NOT NULL
);

CREATE TABLE IF NOT EXISTS gaming_seat_statuses(
  id smallserial PRIMARY KEY,
  status varchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS maintenance_request_status(
  id smallserial PRIMARY KEY,
  status varchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS booking_statuses(
  id smallserial PRIMARY KEY,
  status varchar(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS discount_statuses(
  id smallserial PRIMARY KEY,
  discount_percentage smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS job_titles(
  id smallserial PRIMARY KEY,
  title text NOT NULL,
  description text NOT NULL,
  access_rights text NOT NULL
);

CREATE TABLE IF NOT EXISTS clubs(
  id serial PRIMARY KEY,
  address text NOT NULL,
  phone_number char(11) NOT NULL,
  seat_count smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS employees(
  id serial PRIMARY KEY,
  job_title_id smallint NOT NULL,
  club_id smallint NOT NULL,
  name text NOT NULL,
  last_name text NOT NULL,
  patronymic text NULL,
  passport_data json NOT NULL,
  hire_date date NOT NULL,
  fire_date date NULL,
  salary integer NOT NULL,
  login varchar(30) NOT NULL UNIQUE,
  password_hash char(60) NOT NULL
);
COMMENT ON COLUMN employees.salary IS 'salary per month';
COMMENT ON COLUMN employees.password_hash IS 'bcrypt base64';

CREATE TABLE IF NOT EXISTS gaming_seats(
  id integer PRIMARY KEY,
  club_id smallint NOT NULL,
  configuration_id integer NOT NULL,
  status_id smallint NOT NULL
);

CREATE TABLE IF NOT EXISTS bookings(
  id integer PRIMARY KEY,
  issuer_id integer NOT NULL,
  status_id smallint NOT NULL,
  gaming_seat_id integer NOT NULL,
  client_phone_number char(11) NOT NULL,
  creation_timestamp timestamp without time zone NOT NULL,
  start_timestamp timestamp without time zone NOT NULL,
  end_timestamp timestamp without time zone NOT NULL
);

ALTER TABLE bookings
  DROP CONSTRAINT IF EXISTS bookings_no_overlap;
ALTER TABLE bookings
  ADD CONSTRAINT bookings_no_overlap EXCLUDE USING gist (
    gaming_seat_id WITH =,
    tsrange(start_timestamp, end_timestamp) WITH &&
  );

CREATE TABLE IF NOT EXISTS sessions(
  id integer PRIMARY KEY,
  gaming_seat_id integer NOT NULL,
  client_phone_number char(11) NOT NULL,
  start_timestamp timestamp without time zone NOT NULL,
  end_timestamp timestamp without time zone NOT NULL,
  booking_id integer NULL
);

CREATE TABLE IF NOT EXISTS shift(
  id integer PRIMARY KEY,
  start_timestamp timestamp without time zone NOT NULL,
  end_timestamp timestamp without time zone NOT NULL,
  employee_id integer NOT NULL
);

CREATE TABLE IF NOT EXISTS maintenance_requests(
  id integer PRIMARY KEY,
  creation_timestamp timestamp without time zone NOT NULL,
  gaming_seat_id integer NULL,
  status smallint NOT NULL,
  description text NOT NULL,
  executor_id integer NULL,
  issuer_id integer NOT NULL,
  -- version or last_modified for conflict detection:
  last_modified timestamp without time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS clients(
  phone_number char(11) PRIMARY KEY,
  discount_status smallint NOT NULL,
  password_hash char(60) NOT NULL,
  registration_timestamp timestamp without time zone NOT NULL
);
COMMENT ON COLUMN clients.password_hash IS 'bcrypt base64';

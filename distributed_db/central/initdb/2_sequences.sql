-- club1 id sequences (N=4, offset=1)
CREATE SEQUENCE IF NOT EXISTS gaming_seats_seq START 4 INCREMENT 4 OWNED BY gaming_seats.id;
CREATE SEQUENCE IF NOT EXISTS bookings_seq START 4 INCREMENT 4 OWNED BY bookings.id;
CREATE SEQUENCE IF NOT EXISTS sessions_seq START 4 INCREMENT 4 OWNED BY sessions.id;
CREATE SEQUENCE IF NOT EXISTS shift_seq START 4 INCREMENT 4 OWNED BY shift.id;
CREATE SEQUENCE IF NOT EXISTS maintenance_requests_seq START 4 INCREMENT 4 OWNED BY maintenance_requests.id;

-- Set default values to nextval
ALTER TABLE gaming_seats ALTER COLUMN id SET DEFAULT nextval('gaming_seats_seq');
ALTER TABLE bookings ALTER COLUMN id SET DEFAULT nextval('bookings_seq');
ALTER TABLE sessions ALTER COLUMN id SET DEFAULT nextval('sessions_seq');
ALTER TABLE shift ALTER COLUMN id SET DEFAULT nextval('shift_seq');
ALTER TABLE maintenance_requests ALTER COLUMN id SET DEFAULT nextval('maintenance_requests_seq');

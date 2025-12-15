-- Create admin user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'admin') THEN
        CREATE USER admin WITH PASSWORD 'password' SUPERUSER CREATEDB CREATEROLE;
    END IF;
END $$;

-- Create database if not exists (using template trick)
-- Note: This will show an error if DB exists, but won't stop execution
CREATE DATABASE computer_club_rdb OWNER admin;

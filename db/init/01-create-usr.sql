-- File: db/init/01-create-usr.sql

DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'viihna') THEN
        CREATE USER viihna WITH PASSWORD 'CHANGEME' CREATEDB;
    END IF;
END
$$;

-- set as default owner for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO viihna;

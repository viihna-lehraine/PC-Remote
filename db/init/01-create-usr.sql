-- File: db/init/01-create-usr.sql

DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'viihna') THEN
        CREATE USER viihna WITH PASSWORD 'CHANGEME' CREATEDB;
    END IF;
END
$$;


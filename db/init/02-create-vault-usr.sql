-- File: db/init/02_create_vault_user.sql

GRANT CONNECT ON DATABASE postgres TO vault_mgr;
GRANT USAGE ON SCHEMA public TO vault_mgr;
GRANT CREATE ON SCHEMA public TO vault_mgr;
ALTER ROLE vault_mgr WITH NOINHERIT;

GRANT CREATE ON DATABASE postgres TO vault_mgr;
ALTER ROLE vault_mgr WITH CREATEROLE;
ALTER ROLE vault_mgr WITH CREATEROLE NOCREATEDB NOSUPERUSER;

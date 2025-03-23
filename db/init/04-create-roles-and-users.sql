-- File: db/init/04-create-roles-and-users.sql

-- create roles
INSERT INTO roles (name, description) VALUES
    ('admin', 'Administrator role with full permissions'),
    ('user', 'Regular user with limited permissions');

-- Create users (MAKE SURE PASSWORDS ARE HASHED, THIS IS AN EXAMPLE)
INSERT INTO users (username, password_hash, email) VALUES
    ('admin_user', 'hashed_password_1', 'admin@example.com'),
    ('regular_user', 'hashed_password_2', 'user@example.com');

-- assign roles to users
INSERT INTO user_roles (user_id, role_id)
    SELECT u.id, r.id
    FROM users u
    JOIN roles r ON r.name = 'admin'
    WHERE u.username = 'admin_user';

INSERT INTO user_roles (user_id, role_id)
    SELECT u.id, r.id
    FROM users u
    JOIN roles r ON r.name = 'user'
    WHERE u.username = 'regular_user';

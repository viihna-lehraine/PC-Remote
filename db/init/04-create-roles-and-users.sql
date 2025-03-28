-- File: db/init/04-create-roles-and-users.sql

-- create roles
INSERT INTO roles (name, description) VALUES
    ('admin', 'Administrator role with full permissions'),
	('trusted_user', 'Trusted user with elevated permissions'),
    ('user', 'Regular user with limited permissions'),
	('guest', 'Guest user with minimal permissions');

-- Create users (MAKE SURE PASSWORDS ARE HASHED, THIS IS AN EXAMPLE)
INSERT INTO users (username, password_hash, email) VALUES
    ('viihna', 'hashed_password_1', NULL),
    ('screech', 'hashed_password_2', NULL);

-- assign roles to users
INSERT INTO user_roles (user_id, role_id)
    SELECT u.id, r.id
    FROM users u
    JOIN roles r ON r.name = 'admin'
    WHERE u.username = 'viihna';

INSERT INTO user_roles (user_id, role_id)
    SELECT u.id, r.id
    FROM users u
    JOIN roles r ON r.name = 'trusted_user'
    WHERE u.username = 'screech';

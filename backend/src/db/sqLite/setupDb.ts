// File: backend/src/db/microSql/setupDb.ts

import Database from 'better-sqlite3';
import argon2 from 'argon2';

const db = new Database('./db.sqlite', { verbose: console.log });

// Create the users table if it doesn't exist
db.prepare(
	`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    password TEXT NOT NULL
  );
`
).run();

async function setup() {
	const hashedPassword = await argon2.hash('adminpassword');

	// Insert admin user into the users table
	const stmt = db.prepare('INSERT INTO users (username, password) VALUES (?, ?)');
	stmt.run('admin', hashedPassword);

	console.log('Admin user added');
}

setup().catch(err => console.error(err));

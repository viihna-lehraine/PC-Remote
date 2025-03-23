// File: backend/src/services/db.ts

import knex from 'knex';
import { getDbCredentials } from './vault.js';
import { env } from '../core/index.js';

async function createDbConnection() {
	const { username, password } = await getDbCredentials();

	// initialize Knex dynamic credentials
	const db = knex({
		client: 'pg',
		connection: {
			host: env.DB_HOST,
			port: env.DB_PORT,
			user: username,
			password: password,
			database: env.DB_NAME,
			ssl: { rejectUnauthorized: true }
		}
	});

	return db;
}

export default createDbConnection;

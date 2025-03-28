// File: backend/src/db/client.ts

import { getDatabaseCredentials } from '../services/vaultClient.js';
import { env } from '../core/index.js';
import { Pool } from 'pg';
import fs from 'fs/promises';
import { appMode } from '../core/index.js';

let pool: Pool;

export async function initDb(): Promise<void> {
	if (appMode !== 'dev') {
		const creds = await getDatabaseCredentials();

		pool = new Pool({
			user: creds.username,
			password: creds.password,
			host: env.DB_NAME,
			port: env.DB_PORT,
			database: 'postgres',
			ssl: {
				ca: await fs.readFile(`${env.ROOT_CA_PATH}`)
			}
		});
	}
}

export function getDb(): Pool | void {
	if (appMode === 'dev') {
		if (!pool) {
			throw new Error('Database not initialized. Call initDb() first.');
		}

		return pool;
	}
}

// File: backend/src/services/vault.ts

import { default as Vault } from 'node-vault';
import { env } from '../core/index.js';

const vault = Vault({
	apiVersion: env.VAULT_API_VERSION,
	endpoint: env.VAULT_ENDPOINT,
	token: env.VAULT_TOKEN
});

export async function getDbCredentials() {
	try {
		const { data } = await vault.read(`database/creds/${env.BACKEND_DB_APPROLE}`);
		return data;
	} catch (error) {
		console.error(`Error getting credentials from Vault:`, error);
		throw new Error(`Unabkle to retrieve database credentials`);
	}
}

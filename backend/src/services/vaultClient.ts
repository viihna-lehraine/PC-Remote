// File: backend/src/services/vaultClient.ts

import { AppRoleCredentials, VaultDBCredentials } from '../types/index.js';
import axios from 'axios';
import { env } from '../core/index.js';
import fs from 'fs/promises';
import { Agent as HttpsAgent } from 'https';
import { decryptSopsFile } from '../utils/index.js';
import path from 'path';

let cachedSessionSecret: {
	value: Buffer;
	expiresAt: number;
} | null = null;
let cachedVaultToken: { token: string; expiresAt: number } | null = null;
let cachedDbCreds: { creds: VaultDBCredentials; expiresAt: number } | null = null;
let cachedAppRole: { role_id: string; secret_id: string } | null = null;
let cachedPepper: { value: string; expiresAt: number } | null = null;

const VAULT_LOGIN_PATH = `${env.VAULT_ADDR}/${env.VAULT_API_VERSION}/auth/approle/login`;
const DB_CREDS_PATH = `${env.VAULT_ADDR}/${env.VAULT_API_VERSION}/postgresql/creds/viihna-app`;

export async function getAppRoleCreds(): Promise<{ role_id: string; secret_id: string }> {
	if (cachedAppRole) return cachedAppRole;

	const approlePath = path.resolve(env.APPROLE_CREDS_PATH);
	const json = await decryptSopsFile<AppRoleCredentials>(approlePath);

	if (!json.role_id || !json.secret_id) {
		throw new Error('Missing role_id or secret_id in decrypted AppRole credentials');
	}

	cachedAppRole = { role_id: json.role_id, secret_id: json.secret_id };
	return cachedAppRole;
}

export async function getDatabaseCredentials(): Promise<VaultDBCredentials> {
	const now = Date.now();

	if (cachedDbCreds && cachedDbCreds.expiresAt > now + 10_000) {
		return cachedDbCreds.creds;
	}

	const token = await getVaultToken();
	const httpsAgent = new HttpsAgent({
		ca: await fs.readFile(`${env.ROOT_CA_PATH}`, 'utf-8')
	});
	const { data } = await axios.get(DB_CREDS_PATH, {
		headers: {
			'X-Vault-Token': token
		},
		httpsAgent
	});
	const creds: VaultDBCredentials = {
		username: data.data.username,
		password: data.data.password,
		ttl: data.data.ttl,
		lease_id: data.lease_id,
		lease_duration: data.lease_duration
	};
	cachedDbCreds = {
		creds,
		expiresAt: now + data.lease_duration * 1000
	};

	return creds;
}

export async function getPepper(): Promise<string> {
	if (cachedPepper && cachedPepper.expiresAt > Date.now() + 10_000) {
		return cachedPepper.value;
	}

	const token = await getVaultToken();
	const httpsAgent = new HttpsAgent({
		ca: await fs.readFile(env.ROOT_CA_PATH, 'utf-8')
	});

	const { data } = await axios.get(
		`${env.VAULT_ADDR}/${env.VAULT_API_VERSION}/secret/data/pc-remote/pepper`,
		{
			headers: { 'X-Vault-Token': token },
			httpsAgent
		}
	);

	const pepper: string = data.data.data.value;
	cachedPepper = {
		value: pepper,
		expiresAt: Date.now() + 60 * 60 * 1000 // 1h
	};

	return pepper;
}

export async function getSessionSecret(): Promise<Buffer> {
	const now = Date.now();

	if (cachedSessionSecret && cachedSessionSecret.expiresAt > now + 10_000) {
		return cachedSessionSecret.value;
	}

	const token = await getVaultToken();
	const httpsAgent = new HttpsAgent({
		ca: await fs.readFile(env.ROOT_CA_PATH, 'utf-8')
	});

	const { data } = await axios.get(
		`${env.VAULT_ADDR}/${env.VAULT_API_VERSION}/secret/data/pc-remote/session-secret`,
		{
			headers: { 'X-Vault-Token': token },
			httpsAgent
		}
	);

	const secret = Buffer.from(data.data.data.session_secret, 'hex');

	cachedSessionSecret = {
		value: secret,
		expiresAt: now + 60 * 60 * 1000 // 1h
	};

	return secret;
}

export async function getVaultToken() {
	const now = Date.now();
	const { role_id, secret_id } = await getAppRoleCreds();

	if (cachedVaultToken && cachedVaultToken.expiresAt > now + 10_000) {
		return cachedVaultToken.token;
	}

	const ca = await fs.readFile(`${env.ROOT_CA_PATH}`, 'utf-8');
	const httpsAgent = new HttpsAgent({
		ca
	});

	const { data } = await axios.post(VAULT_LOGIN_PATH, { role_id, secret_id }, { httpsAgent });

	const ttlMs = data.auth.lease_duration * 1000;

	cachedVaultToken = {
		token: data.auth.client_token,
		expiresAt: Date.now() + ttlMs
	};

	return cachedVaultToken.token;
}

export async function verifyAppRoleCreds(): Promise<boolean> {
	try {
		const creds = await getAppRoleCreds();
		return typeof creds.role_id === 'string' && typeof creds.secret_id === 'string';
	} catch {
		return false;
	}
}

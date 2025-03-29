// File: backend/src/core/loadEnv.ts

import { EnvVars, NodeEnv } from '../../types/index.js';
import dotenv from 'dotenv';
import fs from 'fs';
import { appMode } from './loadAppMode.js';
import { absolutePaths } from '../../data/paths.js';
import { parseIntStrict, parseString } from '../helpers/parse.js';

let envPath: string;

if (appMode === 'dev') {
	envPath = absolutePaths.devEnv.main;
} else if (appMode === 'devd') {
	envPath = absolutePaths.devDEnv.main;
} else if (appMode === 'prod') {
	envPath = absolutePaths.prodEnv.main;
} else {
	throw new Error(`Invalid APP_MODE: ${appMode}`);
}

dotenv.config({ path: envPath });

const loadEnv = (filePath = envPath): EnvVars => {
	try {
		if (!fs.existsSync(filePath)) {
			throw new Error(`.env file not found at ${filePath}`);
		}

		const rawEnvVars = fs
			.readFileSync(filePath, 'utf-8')
			.split('\n')
			.filter(line => line.trim() && !line.startsWith('#'))
			.reduce((acc, line) => {
				const [key, ...valueParts] = line.split('=');
				acc[key.trim()] = valueParts.join('=').trim();
				return acc;
			}, {} as Record<string, string>);

		const getEnvVar = <T>(key: keyof EnvVars, parser: (val: string) => T): T => {
			const value = rawEnvVars[key];
			if (value === undefined || value === '') {
				throw new Error(`Missing required environment variable: ${key}`);
			}
			return parser(value);
		};

		return {
			NODE_ENV: getEnvVar('NODE_ENV', parseString) as NodeEnv,
			APPROLE_CREDS_PATH: getEnvVar('APPROLE_CREDS_PATH', parseString),
			DOCKER_SUBNET_1: getEnvVar('DOCKER_SUBNET_1', parseString),
			DOCKER_SUBNET_2: getEnvVar('DOCKER_SUBNET_2', parseString),
			LAN_IP_ADDR: getEnvVar('LAN_IP_ADDR', parseString),
			LISTEN_ADDR: getEnvVar('LISTEN_ADDR', parseString),
			LOG_DIR: getEnvVar('LOG_DIR', parseString),
			LOG_LEVEL: getEnvVar('LOG_LEVEL', parseString),
			BACKEND_PORT: getEnvVar('BACKEND_PORT', parseIntStrict),
			DEV_PORT: getEnvVar('DEV_PORT', parseIntStrict),
			WS_PORT: getEnvVar('WS_PORT', parseIntStrict),
			SOPS_CONFIG: getEnvVar('SOPS_CONFIG', parseString),
			SOPS_PGP_KEY_ID: getEnvVar('SOPS_PGP_KEY_ID', parseString),
			VAULT_ADDR: getEnvVar('VAULT_ADDR', parseString),
			VAULT_API_VERSION: getEnvVar('VAULT_API_VERSION', parseString),
			VAULT_TOKEN: getEnvVar('VAULT_TOKEN', parseString),
			DB_HOST: getEnvVar('DB_HOST', parseString),
			DB_PORT: getEnvVar('DB_PORT', parseIntStrict),
			DB_NAME: getEnvVar('DB_NAME', parseString),
			ROOT_CA_PATH: getEnvVar('ROOT_CA_PATH', parseString)
		};
	} catch (error) {
		console.error(
			`Error loading environment variables: ${error instanceof Error ? error.message : error}`
		);
		process.exit(1);
	}
};

export const env = loadEnv();

// File: backend/src/core/loadEnv.ts

import { EnvVars, NodeEnv } from '../types/index.js';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parseIntStrict, parseString } from '../utils/parse.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const envPath = path.resolve(__dirname, '../../config/.env');

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
			LAN_IP_ADDR: getEnvVar('LAN_IP_ADDR', parseString),
			LISTEN_ADDR: getEnvVar('LISTEN_ADDR', parseString),
			LOG_DIR: getEnvVar('LOG_DIR', parseString),
			LOG_LEVEL: getEnvVar('LOG_LEVEL', parseString),
			BACKEND_PORT: getEnvVar('BACKEND_PORT', parseIntStrict),
			DEV_PORT: getEnvVar('DEV_PORT', parseIntStrict),
			WS_PORT: getEnvVar('WS_PORT', parseIntStrict)
		};
	} catch (error) {
		console.error(
			`Error loading environment variables: ${error instanceof Error ? error.message : error}`
		);
		process.exit(1);
	}
};

export const env = loadEnv();

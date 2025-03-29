// File: backend/src/core/env/loadFlags.ts

import { Flags } from '../../types/index.js';
import dotenv from 'dotenv';
import fs from 'fs';
import { parseBoolean } from '../helpers/parse.js';
import { appMode } from './loadAppMode.js';
import { absolutePaths } from '../../data/paths.js';

let envPath: string;

if (appMode === 'dev') {
	envPath = absolutePaths.devEnv.flags;
} else if (appMode === 'devd') {
	envPath = absolutePaths.devDEnv.flags;
} else if (appMode === 'prod') {
	envPath = absolutePaths.prodEnv.flags;
} else {
	throw new Error(`Invalid APP_MODE: ${appMode}`);
}

dotenv.config({ path: envPath });

const loadFlags = (filePath = envPath): Flags => {
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

		const getEnvVar = <T>(key: keyof Flags, parser: (val: string) => T): T => {
			const value = rawEnvVars[key];
			if (value === undefined || value === '') {
				throw new Error(`Missing required environment variable: ${key}`);
			}
			return parser(value);
		};

		return {
			USE_TLS: getEnvVar('USE_TLS', parseBoolean),
			USE_VAULT: getEnvVar('USE_VAULT', parseBoolean),
			USE_VAULT_CACHE: getEnvVar('USE_VAULT_CACHE', parseBoolean)
		};
	} catch (error) {
		console.error(
			`Error loading feature flags: ${error instanceof Error ? error.message : error}`
		);
		process.exit(1);
	}
};

export const flags = loadFlags();

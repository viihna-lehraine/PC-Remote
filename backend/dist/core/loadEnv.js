// File: backend/src/core/loadEnv.ts
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parseIntStrict, parseString } from '../utils/parse.js';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.resolve(__dirname, '../../config/env/.env');
dotenv.config({ path: envPath });
const loadEnv = (filePath = envPath) => {
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
        }, {});
        const getEnvVar = (key, parser) => {
            const value = rawEnvVars[key];
            if (value === undefined || value === '') {
                throw new Error(`Missing required environment variable: ${key}`);
            }
            return parser(value);
        };
        return {
            NODE_ENV: getEnvVar('NODE_ENV', parseString),
            DOCKER_SUBNET_1: getEnvVar('DOCKER_SUBNET_1', parseString),
            DOCKER_SUBNET_2: getEnvVar('DOCKER_SUBNET_2', parseString),
            LAN_IP_ADDR: getEnvVar('LAN_IP_ADDR', parseString),
            LISTEN_ADDR: getEnvVar('LISTEN_ADDR', parseString),
            LOG_DIR: getEnvVar('LOG_DIR', parseString),
            LOG_LEVEL: getEnvVar('LOG_LEVEL', parseString),
            BACKEND_PORT: getEnvVar('BACKEND_PORT', parseIntStrict),
            DEV_PORT: getEnvVar('DEV_PORT', parseIntStrict),
            WS_PORT: getEnvVar('WS_PORT', parseIntStrict),
            VAULT_API_VERSION: getEnvVar('VAULT_API_VERSION', parseString),
            VAULT_ENDPOINT: getEnvVar('VAULT_ENDPOINT', parseString),
            VAULT_TOKEN: getEnvVar('VAULT_TOKEN', parseString),
            BACKEND_DB_APPROLE: getEnvVar('BACKEND_DB_APPROLE', parseString),
            DB_HOST: getEnvVar('DB_HOST', parseString),
            DB_PORT: getEnvVar('DB_PORT', parseIntStrict),
            DB_NAME: getEnvVar('DB_NAME', parseString)
        };
    }
    catch (error) {
        console.error(`Error loading environment variables: ${error instanceof Error ? error.message : error}`);
        process.exit(1);
    }
};
export const env = loadEnv();
//# sourceMappingURL=loadEnv.js.map
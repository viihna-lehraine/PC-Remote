// File: backend/src/types/app.ts

export interface AppRegex {
	email: RegExp;
	password: RegExp;
	username: RegExp;
}

export interface Denylist {
	ips: string[];
	userAgents: string[];
	hostnames: string[];
}

export interface EnvVars {
	NODE_ENV: NodeEnv;

	DOCKER_SUBNET_1: string;
	DOCKER_SUBNET_2: string;

	LAN_IP_ADDR: string;
	LISTEN_ADDR: string;

	BACKEND_PORT: number;
	DEV_PORT: number;
	WS_PORT: number;

	LOG_DIR: string;
	LOG_LEVEL: string;

	VAULT_API_VERSION: string;
	VAULT_ENDPOINT: string;
	VAULT_TOKEN: string;
	BACKEND_DB_APPROLE: string;

	DB_HOST: string;
	DB_PORT: number;
	DB_NAME: string;
}

export type NodeEnv = 'dev' | 'prod';

export interface SanitationUtils {
	html(userInput: string): string;
}

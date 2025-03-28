// File: backend/src/types/app.ts

export type AppMode = 'dev' | 'devd' | 'prod';

export interface AppRegex {
	css: RegExp;
	email: RegExp;
	js: RegExp;
	password: RegExp;
	username: RegExp;
}

export interface AppRoleCredentials {
	role_id: string;
	secret_id: string;
}

export type CachedValue<T> = {
	data: T;
	expires: number;
};

export interface Denylist {
	ips: string[];
	userAgents: string[];
	hostnames: string[];
}

export interface EnvVars {
	NODE_ENV: NodeEnv;

	APPROLE_CREDS_PATH: string;

	DOCKER_SUBNET_1: string;
	DOCKER_SUBNET_2: string;

	LAN_IP_ADDR: string;
	LISTEN_ADDR: string;

	BACKEND_PORT: number;
	DEV_PORT: number;
	WS_PORT: number;

	LOG_DIR: string;
	LOG_LEVEL: string;

	SOPS_CONFIG: string;
	SOPS_PGP_KEY_ID: string;

	VAULT_ADDR: string;
	VAULT_API_VERSION: string;
	VAULT_TOKEN: string;

	DB_HOST: string;
	DB_PORT: number;
	DB_NAME: string;

	ROOT_CA_PATH: string;
}

export interface Flags {
	USE_TLS: boolean;
	USE_VAULT: boolean;
	USE_VAULT_CACHE: boolean;
}

export type NodeEnv = 'dev' | 'prod';

export interface SanitationUtils {
	html(userInput: string): string;
}

export interface SecureSessionPluginOptions {
	key: Buffer;
	cookie: {
		path: string;
		httpOnly: boolean;
		sameSite: 'strict' | 'lax' | 'none';
		secure: boolean;
	};
}

export interface VaultDBCredentials {
	username: string;
	password: string;
	ttl: number;
	lease_id: string;
	lease_duration: number;
}

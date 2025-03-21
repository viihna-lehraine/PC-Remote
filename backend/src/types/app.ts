// File: backend/src/types/app.ts

export interface Denylist {
	ips: string[];
	userAgents: string[];
	hostnames: string[];
}

export interface EnvVars {
	NODE_ENV: NodeEnv;

	LAN_IP_ADDR: string;
	LISTEN_ADDR: string;

	BACKEND_PORT: number;
	DEV_PORT: number;
	WS_PORT: number;

	LOG_DIR: string;
	LOG_LEVEL: string;
}

export type NodeEnv = 'dev' | 'prod';

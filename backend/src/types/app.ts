// File: backend/src/types/app.ts

export interface EnvVars {
	LAN_IP_ADDR: string;
	LISTEN_ADDR: string;

	BACKEND_PORT: number;
	WS_PORT: number;

	LOG_DIR: string;
	LOG_LEVEL: string;
}

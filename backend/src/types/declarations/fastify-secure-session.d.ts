// File: backend/src/types/declarations/fastify-secure-session.d.ts

import '@fastify/secure-session';

declare module '@fastify/secure-session' {
	interface Session {
		user?: { id: number; username: string };
		set(key: string, value: unknown): void;
		get<T>(key: string): T | undefined;
		delete(): void;
	}
}

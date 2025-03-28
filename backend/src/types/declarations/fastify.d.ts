// File: backend/src/types/declarations/fastify.d.ts

import 'fastify';
import '@fastify/secure-session';

declare module 'fastify' {
	interface FastifyRequest {
		session: import('@fastify/secure-session').Session;
	}
}

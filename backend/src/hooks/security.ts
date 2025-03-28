// File: backend/src/hooks/security.ts

import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

export function securityHeaderHook(app: FastifyInstance): void {
	app.addHook('onRequest', async (_request: FastifyRequest, reply: FastifyReply) => {
		reply.header('Access-Control-Allow-Origin', '*');
		reply.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
		reply.header('Access-Control-Allow-Headers', 'Content-Type');
		reply.header('Access-Control-Allow-Credentials', 'true');
		reply.header('Origin-Agent-Cluster', '?1');
	});
}

// File: backend/src/hooks/permissions.ts

import { FastifyInstance } from 'fastify';

export function enforcePermissionsPolicies(app: FastifyInstance): void {
	app.addHook('onSend', (_req, reply, _payload, done) => {
		reply.header('Permissions-Policy', 'geolocation=(), camera=(), microphone=()');
		done();
	});
}

// File: backend/src/hooks/permissions.ts

import { FastifyInstance } from 'fastify';
import { appMode } from '../core/index.js';

export function enforcePermissionsPolicies(app: FastifyInstance): void {
	if (appMode !== 'dev') {
		app.addHook('onSend', (_req, reply, _payload, done) => {
			reply.header('Permissions-Policy', 'geolocation=(), camera=(), microphone=()');
			done();
		});
	}
}

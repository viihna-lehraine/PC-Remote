// File: backend/src/hooks/auth.ts

import { FastifyInstance } from 'fastify';
import { appMode } from '../core/index.js';

export function globalAuthGuard(app: FastifyInstance): void {
	try {
		if (appMode !== 'dev') {
			app.addHook('onRequest', async (request, reply) => {
				const user = request.session.get('user');
				if (!user) {
					console.error('No user found in session. Unauthorized request.');
					return reply.code(401).send({ error: 'Unauthorized' });
				}
			});
		}
	} catch (error) {
		console.error('Error in global auth guard:', error);
	}
}

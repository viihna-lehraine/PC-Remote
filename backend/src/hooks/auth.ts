// File: backend/src/hooks/auth.ts

import { FastifyInstance } from 'fastify';

export function globalAuthGuard(app: FastifyInstance): void {
	app.addHook('onRequest', async (request, reply) => {
		const user = request.session.get('user');
		if (!user) {
			return reply.code(401).send({ error: 'Unauthorized' });
		}
	});
}

// File: backend/src/hooks/enforceProxy.ts

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { getViteStatus } from '../plugins/vitePing.js';

export const enforceReverseProxy = (app: FastifyInstance) => {
	app.addHook('onRequest', async (req: FastifyRequest, reply: FastifyReply) => {
		const xfwd = req.headers['x-forwarded-for'];

		if (!getViteStatus() && !xfwd) {
			req.log.warn(
				'[Security] Blocked direct request without reverse proxy and dev mode disengaged.'
			);
			return reply.code(403).send({ error: 'Access denied' });
		}
	});
};

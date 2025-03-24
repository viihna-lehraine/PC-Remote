// File: backend/src/guards/auth.ts

import { FastifyRequest, FastifyReply, HookHandlerDoneFunction } from 'fastify';

export function requireAuth(
	request: FastifyRequest,
	reply: FastifyReply,
	done: HookHandlerDoneFunction
) {
	if (!request.session.get('user')) {
		return reply.code(401).send({ error: 'Unauthorized' });
	}

	done();
	return true;
}

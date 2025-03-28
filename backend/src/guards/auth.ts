// File: backend/src/guards/auth.ts

import { FastifyRequest, FastifyReply, HookHandlerDoneFunction } from 'fastify';

export function requireAuth(
	_request: FastifyRequest,
	_reply: FastifyReply,
	done: HookHandlerDoneFunction
) {
	// console.log('Session User:', request.session.get('user')); // TODO: Uncomment this
	// if (!request.session.get('user')) {
	// 	return reply.code(401).send({ error: 'Unauthorized' });
	// }

	done();
	return true;
}

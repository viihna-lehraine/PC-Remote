// File: backend/src/hooks/debug.ts

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';

export function debugRequests(app: FastifyInstance): void {
	app.addHook('onRequest', async (request: FastifyRequest, reply: FastifyReply) => {
		if (request.protocol !== 'https') {
			reply.header('Cross-Origin-Opener-Policy', 'unsafe-none');
		} else {
			reply.header('Cross-Origin-Opener-Policy', 'same-origin');
		}

		console.log('Session:', JSON.stringify(request.session, null, 2));
		console.log('Headers:', JSON.stringify(request.headers, null, 2));
		console.log('Body:', JSON.stringify(request.body, null, 2));
		console.log('Query:', JSON.stringify(request.query, null, 2));
		console.log('Params:', JSON.stringify(request.params, null, 2));
	});
}

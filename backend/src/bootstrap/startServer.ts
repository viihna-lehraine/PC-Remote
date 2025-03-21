// File: backend/src/bootstrap/startServer.ts

import { globalErrorHandler } from '../core/index.js';
import { FastifyInstance } from 'fastify';

export async function startServer(app: FastifyInstance, port: number, host: string): Promise<void> {
	try {
		globalErrorHandler(app);
		await app.listen({ port, host });
		console.log(`Server running at http://${host}:${port}`);
	} catch (err) {
		app.log.error(err);
		process.exit(1);
	}
}

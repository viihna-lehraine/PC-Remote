// File: backend/src/routes/index.ts

import { FastifyInstance } from 'fastify';
import { registerAdminPanel } from './admin.js';
import { registerStaticFiles } from './staticFiles.js';

export function initializeRoutes(app: FastifyInstance): void {
	console.log('Initializing routes...');

	console.log('Registering admin routes...');
	registerAdminPanel(app);

	console.log('Registering static files...');
	registerStaticFiles(app);
}

// File: backend/src/routes/index.ts

import { FastifyInstance } from 'fastify';
import { registerAdminPanel } from './admin.js';
import { registerStaticFiles } from './staticFiles.js';
import filesystemRoutes from './filesystem.js';
import mediaRoutes from './media.js';

export function initializeRoutes(app: FastifyInstance): void {
	console.log('Initializing routes...');

	console.log('Registering admin routes...');
	registerAdminPanel(app);

	console.log('Registering static files...');
	registerStaticFiles(app);

	console.log('Registering filesystem routes...');
	app.register(filesystemRoutes, { prefix: '/api/fs' });

	console.log('Registering media routes...');
	app.register(mediaRoutes, { prefix: '/api/media' });
}

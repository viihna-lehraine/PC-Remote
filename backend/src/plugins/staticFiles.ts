// File: backend/src/plugins/staticFiles.ts

import fastifyStatic from '@fastify/static';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { FastifyInstance } from 'fastify';
import { getViteStatus } from './vitePing.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function registerStaticFiles(app: FastifyInstance): void {
	if (!getViteStatus()) {
		app.register(fastifyStatic, {
			root: join(__dirname, '../../../frontend/public'),
			prefix: '/'
		});
	}
}

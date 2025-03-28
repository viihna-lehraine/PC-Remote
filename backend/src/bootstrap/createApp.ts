// File: backend/src/bootstrap/createApp.ts

import Fastify from 'fastify';
import path from 'path';
import fs from 'fs';
import { env } from '../core/index.js';

export function createApp(): ReturnType<typeof Fastify> {
	fs.mkdirSync(env.LOG_DIR, { recursive: true });
	const logFilePath = path.join(env.LOG_DIR, 'pc-remote.log');

	const app = Fastify({
		logger: {
			level: env.LOG_LEVEL || 'info',
			transport: {
				targets: [
					{
						target: 'pino/file',
						options: { destination: logFilePath, mkdir: true }
					},
					{
						target: 'pino-pretty',
						options: { colorize: true, translateTime: 'SYS:standard' }
					}
				]
			}
		},
		exposeHeadRoutes: false
	});

	app.removeAllContentTypeParsers();
	app.decorate('disablePoweredBy', true);

	return app;
}

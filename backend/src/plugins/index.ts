// File: backend/src/plugins/index.ts

import { EnvVars } from '../types/app.js';
import { checkViteDevServer } from './vitePing.js';
export { getViteStatus, viteReady } from './vitePing.js';
export { registerStaticFiles } from './staticFiles.js';
import securityHeaders from './security.js';
import rateLimit from './rateLimit.js';
import { FastifyInstance } from 'fastify';
import registerSession from './session.js';

export function initializePlugins(env: EnvVars, app: FastifyInstance): void {
	checkViteDevServer(env.LAN_IP_ADDR, env.DEV_PORT);
	app.register(securityHeaders);
	app.register(rateLimit);
	registerSession(app);
}

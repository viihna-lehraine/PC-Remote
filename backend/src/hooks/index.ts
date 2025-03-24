// File: backend/src/hooks/index.ts

import { FastifyInstance } from 'fastify';
import { globalAuthGuard } from './auth.js';
import { blockKnownBots } from './blockBots.js';
import { enforcePermissionsPolicies } from './permissions.js';
import { enforceReverseProxy } from './enforceReverseProxy.js';

export function initializeHooks(app: FastifyInstance): void {
	blockKnownBots(app);
	enforcePermissionsPolicies(app);
	enforceReverseProxy(app);
	globalAuthGuard(app);
}

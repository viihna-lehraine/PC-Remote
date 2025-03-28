// File: backend/src/hooks/index.ts

import { FastifyInstance } from 'fastify';
import { debugRequests } from './debug.js';
import { globalAuthGuard } from './auth.js';
import { blockKnownBots } from './blockBots.js';
import { enforcePermissionsPolicies } from './permissions.js';
import { enforceReverseProxy } from './enforceReverseProxy.js';
import { securityHeaderHook } from './security.js';

export function initializeHooks(app: FastifyInstance): void {
	debugRequests(app);
	blockKnownBots(app);
	enforcePermissionsPolicies(app);
	enforceReverseProxy(app);
	globalAuthGuard(app);
	securityHeaderHook(app);
}

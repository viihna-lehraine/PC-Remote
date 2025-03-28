// File: backend/src/hooks/index.ts
import { debugRequests } from './debug.js';
import { globalAuthGuard } from './auth.js';
import { blockKnownBots } from './blockBots.js';
import { enforcePermissionsPolicies } from './permissions.js';
import { enforceReverseProxy } from './enforceReverseProxy.js';
import { securityHeaderHook } from './security.js';
export function initializeHooks(app) {
    debugRequests(app);
    blockKnownBots(app);
    enforcePermissionsPolicies(app);
    enforceReverseProxy(app);
    globalAuthGuard(app);
    securityHeaderHook(app);
}
//# sourceMappingURL=index.js.map
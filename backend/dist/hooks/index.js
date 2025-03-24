// File: backend/src/hooks/index.ts
import { globalAuthGuard } from './auth.js';
import { blockKnownBots } from './blockBots.js';
import { enforcePermissionsPolicies } from './permissions.js';
import { enforceReverseProxy } from './enforceReverseProxy.js';
export function initializeHooks(app) {
    blockKnownBots(app);
    enforcePermissionsPolicies(app);
    enforceReverseProxy(app);
    globalAuthGuard(app);
}
//# sourceMappingURL=index.js.map
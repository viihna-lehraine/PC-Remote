// File: backend/src/plugins/index.ts
import { checkViteDevServer } from './vitePing.js';
export { getViteStatus, viteReady } from './vitePing.js';
export { registerStaticFiles } from './staticFiles.js';
import securityHeaders from './security.js';
import rateLimit from './rateLimit.js';
import registerSession from './session.js';
export function initializePlugins(env, app) {
    checkViteDevServer(env.LAN_IP_ADDR, env.DEV_PORT);
    app.register(securityHeaders);
    app.register(rateLimit);
    registerSession(app);
}
//# sourceMappingURL=index.js.map
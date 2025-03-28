// File: backend/src/plugins/index.ts
import { checkViteDevServer } from './vitePing.js';
export { getViteStatus, viteReady } from './vitePing.js';
export { registerStaticFiles } from '../routes/staticFiles.js';
import securityHeaders from './security.js';
import rateLimit from './rateLimit.js';
import registerSession from './session.js';
import fsPlugin from './fileSystem.js';
import { appMode } from '../core/index.js';
export function initializePlugins(env, app) {
    checkViteDevServer(env.LAN_IP_ADDR, env.DEV_PORT);
    app.register(securityHeaders);
    app.register(rateLimit);
    if (appMode !== 'dev')
        registerSession(app);
    app.register(fsPlugin);
}
//# sourceMappingURL=index.js.map
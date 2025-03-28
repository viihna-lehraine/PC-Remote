// File: backend/src/server.ts
import { initializePlugins, viteReady } from './plugins/index.js';
import { initializeHooks } from './hooks/index.js';
import { initializeRoutes } from './routes/index.js';
import { patchConsole } from './core/logging.js';
import { env } from './core/index.js';
import { startServer } from './bootstrap/startServer.js';
import { createApp } from './bootstrap/createApp.js';
const app = createApp();
patchConsole(app.log);
initializePlugins(env, app);
initializeHooks(app);
initializeRoutes(app);
console.log('Waiting for viteReady');
await viteReady;
console.log('viteReady resolved');
await import('./ws/index.js');
startServer(app, env.BACKEND_PORT, env.LISTEN_ADDR);
//# sourceMappingURL=server.js.map
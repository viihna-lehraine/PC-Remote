// File: backend/src/plugins/vitePing.ts
import { fetch } from 'undici';
let viteIsRunning = false;
let lastStatus = null;
let viteReadyResolve = null;
export const viteReady = Promise.race([
    new Promise(resolve => {
        viteReadyResolve = resolve;
    }),
    new Promise(resolve => {
        setTimeout(() => {
            console.log('[VITE CHECK] Timeout reached. Proceeding without dev server.');
            resolve();
        }, 1500);
    })
]);
export const getViteStatus = () => viteIsRunning;
export const checkViteDevServer = async (devHost, devPort) => {
    try {
        const res = await fetch(`https://${devHost}:${devPort}`, {
            method: 'HEAD'
        });
        viteIsRunning = res.ok;
        if (viteIsRunning && viteReadyResolve) {
            viteReadyResolve();
            viteReadyResolve = null;
        }
        if (viteIsRunning !== lastStatus) {
            console.log(`[VITE CHECK] Dev server is now ${viteIsRunning ? 'ONLINE' : 'OFFLINE'}`);
            lastStatus = viteIsRunning;
        }
    }
    catch {
        if (lastStatus !== false) {
            console.log(`[VITE CHECK] Dev server is now OFFLINE`);
            lastStatus = false;
        }
        viteIsRunning = false;
    }
    setTimeout(() => checkViteDevServer(devHost, devPort), 10000);
};
//# sourceMappingURL=vitePing.js.map
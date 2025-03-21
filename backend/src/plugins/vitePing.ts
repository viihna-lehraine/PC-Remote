// File: backend/src/plugins/vitePing.ts

import { fetch } from 'undici';

let viteIsRunning = false;
let lastStatus: boolean | null = null;
let viteReadyResolve: (() => void) | null = null;

export const viteReady = new Promise<void>(resolve => {
	viteReadyResolve = resolve;
});

export const getViteStatus = () => viteIsRunning;

export const checkViteDevServer = async (devHost: string, devPort: number): Promise<void> => {
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
	} catch {
		if (lastStatus !== false) {
			console.log(`[VITE CHECK] Dev server is now OFFLINE`);
			lastStatus = false;
		}
		viteIsRunning = false;
	}

	setTimeout(() => checkViteDevServer(devHost, devPort), 10000);
};

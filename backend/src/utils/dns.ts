// File: backend/src/utils/dns.ts

import dns from 'node:dns/promises';

async function tryReverseDNS(ip: string): Promise<string[]> {
	try {
		const res = await Promise.race([
			dns.reverse(ip),
			new Promise<string[]>((_, reject) =>
				setTimeout(() => reject(new Error('Timeout')), 1000)
			)
		]);
		return res as string[];
	} catch {
		return [];
	}
}

export { tryReverseDNS };

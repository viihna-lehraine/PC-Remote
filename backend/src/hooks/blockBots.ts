// File: backend/src/hooks/blockBots.ts

import { Denylist } from '../types/index.js';
import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import path from 'path';
import fs from 'fs';
import CIDRMatcher from 'cidr-matcher';
import { tryReverseDNS } from '../core/utils/dns.js';
import { fileURLToPath } from 'url';
import { appMode } from '../core/index.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const denyListPath = path.resolve(__dirname, '../../config/data/denylist.json');
const denylist: Denylist = JSON.parse(fs.readFileSync(denyListPath, 'utf-8'));
const normalizedIPs = denylist.ips.map(ip => (ip.includes('/') ? ip : `${ip}/32`));
const matcher = new CIDRMatcher(normalizedIPs);

export const blockKnownBots = (app: FastifyInstance) => {
	if (appMode !== 'dev') {
		app.addHook('onRequest', async (req: FastifyRequest, reply: FastifyReply) => {
			const ip = req.ip;
			const ua = (req.headers['user-agent'] ?? '').toLowerCase();

			// match user-agents
			if (denylist.userAgents.some(needle => ua.includes(needle.toLowerCase()))) {
				req.log.warn(`[Bot Detection] Blocked UA ${ua}`);
				return reply.code(403).send({ error: 'Access denied' });
			}

			// match IPs & CIDRs
			if (matcher.contains(ip)) {
				req.log.warn(`[Bot Detection] Blocked IP ${ip}`);
				return reply.code(403).send({ error: 'Access denied' });
			}

			// reverse DNS hostname checks (slowest, last)
			const hostnames = await tryReverseDNS(ip);
			if (hostnames.some(h => denylist.hostnames.some(needle => h.includes(needle)))) {
				req.log.warn(`[Bot Detection] Blocked rDNS host ${hostnames.join(', ')}`);
				return reply.code(403).send({ error: 'Access denied' });
			}
		});
	}
};

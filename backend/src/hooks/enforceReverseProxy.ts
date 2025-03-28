// File: backend/src/hooks/enforceProxy.ts

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { getViteStatus } from '../plugins/vitePing.js';
import { isFromTrustedProxy } from '../utils/index.js';
import { appMode } from '../core/index.js';

export const enforceReverseProxy = (app: FastifyInstance) => {
	if (appMode !== 'dev') {
		app.addHook('onRequest', async (req: FastifyRequest, reply: FastifyReply) => {
			app.decorate('trustProxy', true);

			const xfwd = req.headers['x-forwarded-for'];
			const sourceIP = req.ip;
			const realClientIP = Array.isArray(xfwd) ? xfwd[0] : (xfwd ?? '').split(',')[0].trim();

			req.log.info(
				`[Proxy Trust] Client IP: ${realClientIP || 'N/A'}, Source IP: ${sourceIP}`
			);

			if (!getViteStatus()) {
				const trusted = isFromTrustedProxy(sourceIP);
				req.log.info(`[Proxy Trust] isFromTrustedProxy(${sourceIP}) → ${trusted}`);

				if (!xfwd || !trusted) {
					req.log.warn(
						`[Security] Rejected request from untrusted source IP: ${sourceIP}`
					);
					return reply.code(403).send({ error: 'Access denied' });
				}
			}
		});
	}
};

// File: backend/src/hooks/enforceProxy.ts
import { getViteStatus } from '../plugins/vitePing.js';
import { isFromTrustedProxy } from '../utils/index.js';
export const enforceReverseProxy = (app) => {
    app.addHook('onRequest', async (req, reply) => {
        const xfwd = req.headers['x-forwarded-for'];
        const sourceIP = req.ip;
        const realClientIP = Array.isArray(xfwd) ? xfwd[0] : (xfwd ?? '').split(',')[0].trim();
        req.log.info(`[Proxy Trust] Client IP: ${realClientIP || 'N/A'}, Source IP: ${sourceIP}`);
        if (!getViteStatus()) {
            const trusted = isFromTrustedProxy(sourceIP);
            req.log.info(`[Proxy Trust] isFromTrustedProxy(${sourceIP}) → ${trusted}`);
            if (!xfwd || !trusted) {
                req.log.warn(`[Security] Rejected request from untrusted source IP: ${sourceIP}`);
                return reply.code(403).send({ error: 'Access denied' });
            }
        }
    });
};
//# sourceMappingURL=enforceReverseProxy.js.map
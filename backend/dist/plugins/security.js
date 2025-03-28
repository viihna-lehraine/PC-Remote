// File: backend/src/plugins/security.ts
import cors from '@fastify/cors';
import fp from 'fastify-plugin';
import helmet from '@fastify/helmet';
export default fp(async function securityHeaders(app) {
    app.register(cors, {
        origin: ['https://192.168.50.10', 'http://localhost:3070'], // TODO: extract to env vars
        methods: ['GET', 'POST', 'PUT', 'DELETE'],
        credentials: true // TODO: address. use false if cookies or auth headers are involved
    });
    await app.register(helmet, {
        global: true,
        contentSecurityPolicy: false, // TODO: lock this down later
        crossOriginEmbedderPolicy: true,
        crossOriginResourcePolicy: { policy: 'same-origin' },
        crossOriginOpenerPolicy: { policy: 'same-origin' },
        referrerPolicy: { policy: 'no-referrer' },
        xXssProtection: true
    });
});
//# sourceMappingURL=security.js.map
// File: backend/src/plguins/rateLimit.ts
import fp from 'fastify-plugin';
import rateLimit from '@fastify/rate-limit';
export default fp(async function setupRateLimit(app) {
    app.register(rateLimit, {
        max: 100,
        timeWindow: '1 minute'
    });
});
//# sourceMappingURL=rateLimit.js.map
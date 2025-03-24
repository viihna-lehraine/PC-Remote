// File: backend/src/plugins/session.ts
import fp from 'fastify-plugin';
import secureSession from '@fastify/secure-session';
import { getSessionSecret } from '../services/vaultClient.js';
export default fp(async function (fastify) {
    const key = await getSessionSecret();
    fastify.register(secureSession, {
        key,
        cookie: {
            path: '/',
            httpOnly: true,
            sameSite: 'strict',
            secure: true
        }
    });
});
//# sourceMappingURL=session.js.map
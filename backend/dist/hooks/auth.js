// File: backend/src/hooks/auth.ts
export function globalAuthGuard(app) {
    app.addHook('onRequest', async (request, reply) => {
        const user = request.session.get('user');
        if (!user) {
            return reply.code(401).send({ error: 'Unauthorized' });
        }
    });
}
//# sourceMappingURL=auth.js.map
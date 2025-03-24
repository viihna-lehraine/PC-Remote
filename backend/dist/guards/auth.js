// File: backend/src/guards/auth.ts
export function requireAuth(request, reply, done) {
    if (!request.session.get('user')) {
        return reply.code(401).send({ error: 'Unauthorized' });
    }
    done();
    return true;
}
//# sourceMappingURL=auth.js.map
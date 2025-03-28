// File: backend/src/guards/auth.ts
export function requireAuth(_request, _reply, done) {
    // console.log('Session User:', request.session.get('user')); // TODO: Uncomment this
    // if (!request.session.get('user')) {
    // 	return reply.code(401).send({ error: 'Unauthorized' });
    // }
    done();
    return true;
}
//# sourceMappingURL=auth.js.map
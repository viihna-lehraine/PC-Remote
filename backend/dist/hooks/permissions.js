// File: backend/src/hooks/permissions.ts
export function enforcePermissionsPolicies(app) {
    app.addHook('onSend', (_req, reply, _payload, done) => {
        reply.header('Permissions-Policy', 'geolocation=(), camera=(), microphone=()');
        done();
    });
}
//# sourceMappingURL=permissions.js.map
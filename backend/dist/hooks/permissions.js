// File: backend/src/hooks/permissions.ts
import { appMode } from '../core/index.js';
export function enforcePermissionsPolicies(app) {
    if (appMode !== 'dev') {
        app.addHook('onSend', (_req, reply, _payload, done) => {
            reply.header('Permissions-Policy', 'geolocation=(), camera=(), microphone=()');
            done();
        });
    }
}
//# sourceMappingURL=permissions.js.map
// File: backend/src/guards/role.ts
import { getDb } from '../db/client.js';
import { appMode } from '../core/index.js';
export function requireRole(role) {
    if (appMode !== 'dev') {
        return async function (request, reply) {
            const user = request.session.get('user');
            if (!user)
                return reply.code(401).send({ error: 'Unauthorized' });
            const db = getDb();
            if (db) {
                const { rows } = await db.query(`SELECT 1 FROM user_roles ur
					 JOIN roles r ON ur.role_id = r.id
					 WHERE ur.user_id = $1 AND r.name = $2`, [user.id, role]);
                if (rows.length === 0) {
                    return reply.code(403).send({ error: 'Forbidden' });
                }
            }
        };
    }
    else {
        return;
    }
}
//# sourceMappingURL=role.js.map
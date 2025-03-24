// File: backend/src/guards/role.ts

import { FastifyRequest, FastifyReply } from 'fastify';
import { getDb } from '../db/client.js';

export function requireRole(role: string) {
	return async function (request: FastifyRequest, reply: FastifyReply) {
		const user = request.session.get('user');

		if (!user) return reply.code(401).send({ error: 'Unauthorized' });

		const db = getDb();
		const { rows } = await db.query(
			`SELECT 1 FROM user_roles ur
			 JOIN roles r ON ur.role_id = r.id
			 WHERE ur.user_id = $1 AND r.name = $2`,
			[user.id, role]
		);

		if (rows.length === 0) {
			return reply.code(403).send({ error: 'Forbidden' });
		}
	};
}

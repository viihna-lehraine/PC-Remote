// File: backend/src/routes/filesystem.ts

import { Role } from '../types/index.js';
import { FastifyPluginAsync, FastifyRequest, FastifyReply } from 'fastify';
import { listDirectory } from '../services/filesystemService.js';
import { helpers } from '../core/helpers/index.js';

const typeguards = helpers.typeguards;

const filesystemRoutes: FastifyPluginAsync = async fastify => {
	fastify.get('/browse', async (req: FastifyRequest, reply: FastifyReply) => {
		const { path: relPath = '/' } = req.query as { path?: string };
		const roleHeader = req.headers['x-role'] as string;
		const userRole: Role = typeguards.isRole(roleHeader) ? roleHeader : ('guest' as Role);

		try {
			const entries = await listDirectory(userRole, relPath);
			reply.send({ entries });
		} catch (err) {
			reply.status(403).send({ error: (err as Error).message });
		}
	});
};

export default filesystemRoutes;

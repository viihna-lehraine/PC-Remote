// File: backend/src/routes/media.ts

import { FastifyPluginAsync } from 'fastify';
import fs from 'node:fs/promises';
import path from 'node:path';

const mediaRoutes: FastifyPluginAsync = async fastify => {
	fastify.get('/media', async (req, reply) => {
		const { file } = req.query as { file: string };
		const absPath = path.resolve('/', file);

		try {
			const data = await fs.readFile(absPath);
			const ext = path.extname(absPath).toLowerCase();

			if (ext.match(/\.(png|jpe?g|gif|webp)$/)) {
				reply.type(`image/${ext === '.jpg' ? 'jpeg' : ext.slice(1)}`);
			} else if (ext.match(/\.(mp3|wav|ogg)$/)) {
				reply.type(`audio/${ext.slice(1)}`);
			} else if (ext.match(/\.(mp4|webm|mkv)$/)) {
				reply.type(`video/${ext.slice(1)}`);
			} else {
				return reply.status(415).send({ error: 'Unsupported media type' });
			}

			reply.send(data);
		} catch (err) {
			reply.status(404).send({ error: 'File not found or unreadable' });
		}
	});
};

export default mediaRoutes;

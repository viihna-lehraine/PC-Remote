// File: backend/src/server.ts

import Fastify from 'fastify';
import fastifyStatic from '@fastify/static';
import { fileURLToPath } from 'url';
import { join } from 'path';
import path from 'path';
import { WebSocketServer } from 'ws';

const fastify = Fastify({ logger: true });
const PORT = 3000;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

fastify.register(fastifyStatic, {
	root: join(__dirname, '../../frontend/dist'),
	prefix: '/'
});

const wss = new WebSocketServer({ port: 3001 });

wss.on('connection', ws => {
	console.log('Client connected');

	ws.on('message', message => {
		console.log(`Received: ${message}`);
		ws.send(`Echo: ${message}`);
	});

	ws.on('close', () => console.log('Client disconnected'));
});

const start = async () => {
	try {
		await fastify.listen({ port: PORT, host: '0.0.0.0' });
		console.log(`Server running at http://localhost:${PORT}`);
	} catch (err) {
		fastify.log.error(err);
		process.exit(1);
	}
};

start();

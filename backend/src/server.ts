// File: backend/src/server.ts

import { exec } from 'child_process';
import Fastify from 'fastify';
import fastifyStatic from '@fastify/static';
import { fileURLToPath } from 'url';
import { join } from 'path';
import path from 'path';
import { WebSocketServer } from 'ws';

const fastify = Fastify({ logger: true });
const PORT = 3050;
const WSPORT = 3060;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

fastify.register(fastifyStatic, {
	root: join(__dirname, '../../frontend/dist'),
	prefix: '/'
});

const start = async () => {
	try {
		await fastify.listen({ port: PORT, host: '0.0.0.0' });
		console.log(`Server running at http://192.168.50.10:${PORT}`);
	} catch (err) {
		fastify.log.error(err);
		process.exit(1);
	}
};
start();

try {
	const wss = new WebSocketServer({ port: WSPORT, host: '0.0.0.0' });
	wss.on('connection', ws => {
		console.log('✅ Client connected to WebSocket');

		ws.on('message', message => {
			const command = message.toString();
			console.log(`📩 Received command: ${command}`);

			let shellCommand = '';
			switch (command) {
				case 'toggle':
					shellCommand = 'playerctl play-pause';
					break;
				case 'volume/up':
					shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ +5%';
					break;
				case 'volume/down':
					shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ -5%';
					break;
				case 'mute':
					shellCommand = 'pactl set-sink-mute @DEFAULT_SINK@ toggle';
					break;
				default:
					console.log('⚠️ Unknown command:', command);
					ws.send(`❌ Unknown command: ${command}`);
					return;
			}

			exec(shellCommand, (error, stdout, stderr) => {
				if (error) {
					console.error(`❌ Error executing ${command}: ${error.message}`);
					ws.send(`❌ Error: ${error.message}`);
					return;
				}
				console.log(`✅ Command executed: ${command}`);
				console.log(`📝 Output: ${stdout}`);
				if (stderr) console.error(`⚠️ Stderr: ${stderr}`);
				ws.send(`✅ Executed: ${command}`);
			});
		});

		ws.on('close', () => console.log('⚠️ Client disconnected'));
	});

	console.log(`🚀 WebSocket server running on ws://localhost:${WSPORT}`);
} catch (error: any) {
	console.error(`❌ WebSocket Server Error: ${error.message}`);
	process.exit(1);
}

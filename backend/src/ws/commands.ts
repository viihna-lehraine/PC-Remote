// File: backend/src/ws/commands.ts

import { WebSocket } from 'ws';
import { exec } from 'child_process';
import { speak } from '../core/utils/index.js';
import { commandTTSMap } from '../data/index.js';

export function handleCommandSocket(ws: WebSocket, command: string) {
	if (command.startsWith('tts:')) {
		const phrase = command.slice(4).trim();
		if (!phrase) {
			ws.send('TTS error: empty input');
			return;
		}

		speak(phrase)
			.then(() => ws.send(`TTS: "${phrase}"`))
			.catch(err => {
				console.error(err);
				ws.send(`TTS error: ${err.message}`);
			});
		return;
	}

	let shellCommand = '';

	switch (command) {
		case 'lock':
			shellCommand = 'systemctl suspend';
			break;
		case 'mute':
			shellCommand = 'pactl set-sink-mute @DEFAULT_SINK@ toggle';
			break;
		case 'shutdown':
			shellCommand = 'shutdown -h now';
			break;
		case 'toggle':
			shellCommand = 'playerctl play-pause';
			break;
		case 'volume/up':
			shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ +5%';
			break;
		case 'volume/down':
			shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ -5%';
			break;
		default:
			console.log('Unknown command:', command);
			ws.send(`Unknown command: ${command}`);
			return;
	}

	exec(shellCommand, (error, stdout, stderr) => {
		if (error) {
			console.error(`Error executing ${command}: ${error.message}`);
			ws.send(`Error: ${error.message}`);
			return;
		}
		console.log(`Command executed: ${command}`);
		console.log(`Output: ${stdout}`);
		if (stderr) console.error(`Stderr: ${stderr}`);
		ws.send(`Executed: ${command}`);
	});

	const responses = commandTTSMap[command];
	if (responses?.length) {
		const pick = responses[Math.floor(Math.random() * responses.length)];
		speak(pick).catch(err => {
			console.error('TTS error:', err);
			ws.send(`TTS error: ${err.message}`);
		});
	}
}

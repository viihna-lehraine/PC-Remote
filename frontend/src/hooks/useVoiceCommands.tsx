// File: frontend/src/hooks/useVoiceCommands.tsx

import { useWebSocket } from '../hooks/useWebSocket.js';

export const useVoiceCommands = () => {
	const ws = useWebSocket();

	const startListening = () => {
		const SpeechRecognitionAPI = window.SpeechRecognition || window.webkitSpeechRecognition;

		if (!SpeechRecognitionAPI) {
			console.error('Speech recognition is not supported in this browser.');
			return;
		}

		const recognition = new SpeechRecognitionAPI();
		recognition.lang = 'en-US';
		recognition.continuous = false;
		recognition.interimResults = false;

		recognition.onresult = event => {
			const command = event.results[0][0].transcript.trim().toLowerCase();
			console.log(`Recognized command: ${command}`);

			let wsCommand = '';

			if (command.includes('lock computer')) {
				wsCommand = 'lock';
			} else if (command.includes('shutdown')) {
				wsCommand = 'shutdown';
			} else if (command.includes('increase volume')) {
				wsCommand = 'volume/up';
			} else if (command.includes('decrease volume')) {
				wsCommand = 'volume/down';
			} else if (command.includes('mute')) {
				wsCommand = 'mute';
			} else {
				console.warn('Unrecognized command:', command);
				return;
			}

			if (ws.socket?.readyState === WebSocket.OPEN) {
				ws.socket.send(wsCommand);
			} else {
				console.error('WebSocket is not open');
			}
		};

		recognition.onerror = event => console.error('Speech recognition error:', event.error);

		recognition.start();
	};

	return { startListening };
};

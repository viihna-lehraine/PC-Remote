// File: frontend/src/App.tsx

import { useState, useEffect } from 'react';
import { useWebSocket } from './hooks/useWebSocket.js';
import Chat from './components/Chat.js';
import VoiceCommandButton from './components/VoiceCommandButton.js';
import { WebSocketProvider } from './components/WebSocketProvider.js';

const App = () => {
	const [message, setMessage] = useState('No messages yet');
	const ws = useWebSocket();

	useEffect(() => {
		if (!ws) return;
		ws.onopen = () => console.log('Connected to WebSocket on :3060');
		ws.onmessage = event => setMessage(event.data);
		ws.onerror = error => console.error('WebSocket Error:', error);
		ws.onclose = () => console.log('WebSocket connection closed');
	}, [ws]);

	const sendCommand = (command: string) => {
		if (ws && ws.readyState === WebSocket.OPEN) {
			console.log(`Sending command: ${command}`);
			ws.send(command);
		} else {
			console.error('❌ WebSocket is not open');
		}
	};

	return (
		<div className="app">
			<WebSocketProvider>
				<h1>PC Remote</h1>

				<div className="message-buttons-wrapper">
					<div className="message-wrapper">
						<div className="message">
							<div className="marquee">
								{/* duplicate for smooth looping */}
								<span>Last message: {message}</span>
								<span>Last message: {message}</span>{' '}
							</div>
						</div>
					</div>
					<div className="button-container">
						<button onClick={() => sendCommand('toggle')}>▶️⏸ Play/Pause</button>
						<button onClick={() => sendCommand('volume/up')}>🔊 Volume Up</button>
						<button onClick={() => sendCommand('volume/down')}>🔉 Volume Down</button>
						<button onClick={() => sendCommand('mute')}>🔇 Mute</button>
					</div>
				</div>

				<VoiceCommandButton />

				<Chat />
			</WebSocketProvider>
		</div>
	);
};

const WrappedApp = () => (
	<WebSocketProvider>
		<App />
	</WebSocketProvider>
);

export default WrappedApp;

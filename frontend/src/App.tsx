// File: frontend/src/App.tsx

import { useState, useEffect } from 'react';
import { useWebSocket } from './hooks/useWebSocket.js';
import Chat from './components/Chat.js';
import VoiceCommandButton from './components/VoiceCommandButton.js';
import ConnectionBanner from './components/ConnectionBanner.js';
import { WebSocketProvider } from './components/WebSocketProvider.js';
import './styles/index.css';

const App = () => {
	const [message, setMessage] = useState('No messages yet');
	const { socket } = useWebSocket();

	useEffect(() => {
		console.log('React App is mounted!');
	}, []);

	useEffect(() => {
		if (!socket) return;

		socket.onopen = () => console.log(`Connected to WebSocket on :3060`);
		socket.onmessage = (event: MessageEvent) => setMessage(event.data);
		socket.onerror = (error: Event) => console.error('WebSocket Error:', error);
		socket.onclose = () => console.log('WebSocket connection closed');
	}, [socket]);

	const sendCommand = (command: string) => {
		if (socket && socket.readyState === WebSocket.OPEN) {
			console.log(`Sending command: ${command}`);
			socket.send(command);
		} else {
			console.error(`WebSocket is not open!`);
		}
	};

	return (
		<div className="app">
			<ConnectionBanner /> {/* Optional but recommended */}
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
		</div>
	);
};

const WrappedApp = () => (
	<WebSocketProvider>
		<App />
	</WebSocketProvider>
);

export default WrappedApp;

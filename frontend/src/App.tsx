// File: frontend/src/App.tsx

import { useState, useEffect } from 'react';

const WS_URL = `ws://${window.location.hostname}:3060`;

const ws = new WebSocket(WS_URL);

const App = () => {
	const [message, setMessage] = useState('No messages yet');

	useEffect(() => {
		ws.onopen = () => console.log('Connected to WebSocket on :3060');
		ws.onmessage = event => setMessage(event.data);
		ws.onerror = error => console.error('WebSocket Error:', error);
		ws.onclose = () => console.log('WebSocket connection closed');
	}, []);

	const sendCommand = (command: string) => {
		if (ws.readyState === WebSocket.OPEN) {
			console.log(`🚀 Sending command: ${command}`);
			ws.send(command);
		} else {
			console.error('❌ WebSocket is not open');
		}
	};

	return (
		<div>
			<h1>PC Remote</h1>
			<p>Last message: {message}</p>
			<div className="button-container">
				<button onClick={() => sendCommand('toggle')}>▶️⏸ Play/Pause</button>
				<button onClick={() => sendCommand('volume/up')}>🔊 Volume Up</button>
				<button onClick={() => sendCommand('volume/down')}>🔉 Volume Down</button>
				<button onClick={() => sendCommand('mute')}>🔇 Mute</button>
			</div>
		</div>
	);
};

export default App;

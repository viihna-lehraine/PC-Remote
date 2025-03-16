import { useState, useEffect } from 'react';

const ws = new WebSocket('ws://localhost:3001');

const App = () => {
	const [message, setMessage] = useState('No messages yet');

	useEffect(() => {
		ws.onmessage = event => setMessage(event.data);
	}, []);

	const sendCommand = (command: string) => {
		ws.send(command);
	};

	return (
		<div>
			<h1>PC Remote</h1>
			<p>Last message: {message}</p>
			<button onClick={() => sendCommand('toggle')}>▶️⏸ Play/Pause</button>
			<button onClick={() => sendCommand('volume/up')}>🔊 Volume Up</button>
			<button onClick={() => sendCommand('volume/down')}>🔉 Volume Down</button>
			<button onClick={() => sendCommand('mute')}>🔇 Mute</button>
		</div>
	);
};

export default App;

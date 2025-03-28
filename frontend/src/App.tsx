// File: frontend/src/App.tsx

import { useState, useEffect } from 'react';
import Chat from './react/components/Chat.js';
import { useWebSocket } from './react/hooks/useWebSocket.js';
import VoiceCommandButton from './react/components/buttons/VoiceCommandButton.js';
import ConnectionBanner from './react/components/ConnectionBanner.js';
import { WebSocketProvider } from './react/components/WebSocketProvider.js';
import FileBrowser from './react/components/FileBrowser.js';
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
		<div id="app" className="flex flex-col items-center w-full m-auto">
			<ConnectionBanner />
			<h1>PC Remote</h1>
			<div
				id="message-buttons-wrapper"
				className="flex flex-col items-center w-full gap-2 max-w-full"
			>
				<div
					id="message-wrapper"
					className="flex w-full justify-center mb-2 max-w-[400px] min-w-[250px]"
				>
					<div
						id="message"
						className="flex items-center justify-center px-4 py-3 flex-grow w-full max-w-full min-h-4 text-center bg-[#292929] rounded-lg whitespace-nowrap overflow-hidden text-ellipsis"
					>
						<div id="marquee" className="flex whitespace-nowrap animate-scroll">
							<span className="mr-8">Last message: {message}</span>
							<span className="mr-8">Last message: {message}</span>{' '}
						</div>
					</div>
				</div>
				<div
					id="button-container"
					className="flex flex-col items-center w-full min-w-[250px] max-w-[400px] gap-3 sm:gap-4"
				>
					<button className="custom-button" onClick={() => sendCommand('toggle')}>
						▶️⏸ Play/Pause
					</button>
					<button className="custom-button" onClick={() => sendCommand('volume/up')}>
						🔊 Volume Up
					</button>
					<button className="custom-button" onClick={() => sendCommand('volume/down')}>
						🔉 Volume Down
					</button>
					<button className="custom-button" onClick={() => sendCommand('mute')}>
						🔇 Mute
					</button>
				</div>
			</div>
			<FileBrowser />
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

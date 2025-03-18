// File: frontend/src/Chat.tsx

import { useEffect, useState, useRef } from 'react';

const Chat = () => {
	const [messages, setMessages] = useState<string[]>([]);
	const [input, setInput] = useState('');
	const [isOpen, setIsOpen] = useState(false); // chat visibility toggle
	const ws = useRef<WebSocket | null>(null);
	const username = 'Viihna'; // change per user

	useEffect(() => {
		ws.current = new WebSocket('ws://192.168.50.10:3060');
		ws.current.onmessage = event => {
			const data = event.data.toString();

			if (data.startsWith('chat:')) {
				setMessages(prev => [...prev, data.replace('chat:', '')]);
			}
		};

		return () => {
			ws.current?.close();
		};
	}, []);

	const sendMessage = () => {
		if (ws.current && input.trim()) {
			ws.current.send(`chat:${username}:${input}`);
			setInput('');
		}
	};

	return (
		<div>
			{/* floating chat toggle button */}
			<button className="chat-toggle" onClick={() => setIsOpen(!isOpen)}>
				💬
			</button>

			{/* Chat UI */}
			{isOpen && (
				<div className="chat-container">
					<div className="chat-header">
						<span>Chat</span>
						<button onClick={() => setIsOpen(false)}>❌</button>
					</div>

					<div className="messages">
						{messages.map((msg, index) => (
							<div key={index} className="message">
								{msg}
							</div>
						))}
					</div>

					<input
						type="text"
						value={input}
						onChange={e => setInput(e.target.value)}
						onKeyDown={e => e.key === 'Enter' && sendMessage()}
						placeholder="Type a message..."
					/>
					<button onClick={sendMessage}>Send</button>
				</div>
			)}
		</div>
	);
};

export default Chat;

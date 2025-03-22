// File: frontend/src/components/Chat.tsx

import { useEffect, useState, useRef } from 'react';
import '../styles/components/Chat.css';
import { useWebSocket } from '../hooks/useWebSocket';

const Chat = () => {
	const [messages, setMessages] = useState<string[]>([]);
	const [input, setInput] = useState('');
	const [isOpen, setIsOpen] = useState(false); // chat visibility toggle
	const { socket } = useWebSocket();
	const username = 'Viihna'; // change per user
	const inputRef = useRef<HTMLInputElement | null>(null);

	useEffect(() => {
		if (!socket) return;

		const handleMessage = (event: MessageEvent) => {
			const data = event.data.toString();

			if (data.startsWith('chat:')) {
				setMessages(prev => [...prev, data.replace('chat:', '')]);
			}
		};

		socket.addEventListener('message', handleMessage);

		return () => {
			socket.removeEventListener('message', handleMessage);
		};
	}, [socket]);

	useEffect(() => {
		if (isOpen && inputRef.current) {
			inputRef.current.focus();
			console.log('Chat opened, input field focused!');
		}
	}, [isOpen]);

	const sendMessage = () => {
		if (!socket) {
			console.error('Cannot send message: WebSocket is not available');
			return;
		}

		if (socket.readyState !== WebSocket.OPEN) {
			console.error('Cannot send message: WebSocket not open');
			return;
		}

		if (!input.trim()) return;

		socket.send(`chat:${username}:${input}`);
		setInput('');
	};

	return (
		<div>
			{/* floating chat toggle button */}
			<button className="chat-toggle" onClick={() => setIsOpen(!isOpen)}>
				💬
			</button>

			{/* chat UI */}
			{isOpen && (
				<div className="chat-container" onClick={e => e.stopPropagation()}>
					<div className="chat-header">
						<span>Chat</span>
						<button className="chat-close" onClick={() => setIsOpen(false)}>
							❌
						</button>
					</div>

					<div className="chat-messages">
						{messages.map((msg, index) => (
							<div key={index} className="chat-message">
								{msg}
							</div>
						))}
					</div>

					<div className="chat-input-container" onClick={e => e.stopPropagation()}>
						<input
							ref={inputRef}
							type="text"
							value={input}
							onChange={e => setInput(e.target.value)}
							onKeyDown={e => e.key === 'Enter' && sendMessage()}
							placeholder="Type a message..."
							onClick={e => {
								e.stopPropagation();
								console.log('Clicked input!');
							}}
						/>
						<button
							id="send-btn"
							onMouseDown={e => e.preventDefault()}
							onClick={e => {
								e.stopPropagation();
								console.log('Send button clicked!');
								sendMessage();
							}}
						>
							Send
						</button>
					</div>
				</div>
			)}
		</div>
	);
};

export default Chat;

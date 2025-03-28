// File: frontend/src/react/components/Chat.tsx

import { useEffect, useState, useRef } from 'react';
import { useWebSocket } from '../hooks/useWebSocket.js';

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
			<button
				id="chat-toggle"
				className="custom-button fixed bottom-4 right-4 text-white rounded-full w-[45px] h-[45px] text-[22px] flex items-center justify-center active:transform-none active:shadow-none"
				onClick={() => setIsOpen(!isOpen)}
			>
				💬
			</button>

			{/* chat UI */}
			{isOpen && (
				<div
					id="chat-container"
					className="fixed bottom-[70px] right-4 w-[280px] h-[300px] bg-[#222] text-white rounded-lg overflow-hidden flex flex-col pointer-events-auto"
					onClick={e => e.stopPropagation()}
				>
					<div
						id="chat-header"
						className="flex items-center justify-between bg-[#444] px-3 py-2 font-bold border-b border-[#222]"
					>
						<span>Chat</span>
						<button
							id="chat-close"
							className="bg-none border-none text-white text-[16px] cursor-pointer p-[2px] w-[24px] h-[24px] flex items-center justify-center hover:text-red-400 active:transform-none active:shadow-none"
							onClick={() => setIsOpen(false)}
						>
							❌
						</button>
					</div>

					<div
						id="chat-messages"
						className="h-[200px] overflow-y-auto p-2 bg-[#222] flex flex-col gap-[6px] text-sm"
					>
						{messages.map((msg, index) => (
							<div
								key={index}
								className="chat-message bg-[#444] px-3 py-1.5 rounded-md max-w-[80%] break-words"
							>
								{msg}
							</div>
						))}
					</div>

					<div
						id="chat-input-container"
						className="flex gap-1 p-2 bg-[#222] border-t border-[#444]"
						onClick={e => e.stopPropagation()}
					>
						<input
							id="chat-container-input"
							className="flex-grow p-2 bg-[#333] text-white rounded-md border-none"
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
							className="custom-button active:transform-none active:shadow-none"
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

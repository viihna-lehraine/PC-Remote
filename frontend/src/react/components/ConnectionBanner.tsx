// File: frontend/src/react/components/ConnectionBanner.tsx

import { useWebSocket } from '../hooks/useWebSocket.js';

const ConnectionBanner = () => {
	const { status } = useWebSocket();

	if (status === 'connected') return null;

	const bgColor = status === 'connecting' ? 'bg-[#ffae42]' : 'bg-[#e53935]';

	return (
		<div
			id="connection-banner"
			className={`fixed top-0 left-0 right-0 text-white text-center py-2 font-bold z-[9999] ${bgColor}`}
		>
			🔌{' '}
			{status === 'connecting'
				? 'Connecting to server...'
				: 'Disconnected from server. Reconnecting...'}
		</div>
	);
};

export default ConnectionBanner;

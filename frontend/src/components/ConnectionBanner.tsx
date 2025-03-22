// File: frontend/src/components/ConnectionBanner.tsx

import '../styles/components/ConnectionBanner.css';
import { useWebSocket } from '../hooks/useWebSocket.js';

const ConnectionBanner = () => {
	const { status } = useWebSocket();

	if (status === 'connected') return null;

	return (
		<div className="banner">
			🔌{' '}
			{status === 'connecting'
				? 'Connecting to server...'
				: 'Disconnected from server. Reconnecting...'}
		</div>
	);
};

export default ConnectionBanner;

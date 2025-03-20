// File: frontend/src/components/VoiceCommandButton.tsx

import React from 'react';
import { useVoiceCommands } from '../hooks/useVoiceCommands';

const VoiceCommandButton: React.FC = () => {
	const { startListening } = useVoiceCommands();

	return (
		<button onClick={startListening} style={{ fontSize: '16px', padding: '10px' }}>
			🎤 Activate Voice Control
		</button>
	);
};

export default VoiceCommandButton;

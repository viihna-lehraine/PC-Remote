// File: frontend/src/components/VoiceCommandButton.tsx

import React from 'react';
import { useVoiceCommands } from '../hooks/useVoiceCommands.js';
import '../styles/index.css';

const VoiceCommandButton: React.FC = () => {
	const { startListening } = useVoiceCommands();

	return (
		<button
			id="voice-command-btn"
			className="custom-button bg-blue-700 hover:bg-blue-800"
			onClick={startListening}
		>
			🎤 Activate Voice Control
		</button>
	);
};

export default VoiceCommandButton;

// File: frontend/src/react/components/buttonsVoiceCommandButton.tsx

import { useState } from 'react';

const VoiceCommandButton = () => {
	const [isListening, setIsListening] = useState(false);
	// const [setCommand] = useState<string | null>(null);

	const handleVoiceCommand = () => {
		if (!('SpeechRecognition' in window || 'webkitSpeechRecognition' in window)) {
			alert('Speech recognition is not supported in your browser');
			return;
		}

		const recognition = new (window.SpeechRecognition || window.webkitSpeechRecognition)();
		recognition.lang = 'en-US';
		recognition.interimResults = true;
		recognition.maxAlternatives = 1;

		recognition.onstart = () => {
			setIsListening(true);
		};

		recognition.onresult = (event: SpeechRecognitionEvent) => {
			const transcript = event.results[0][0].transcript;
			// setCommand(transcript);
			sendCommandToServer(transcript);
		};

		recognition.onerror = error => {
			console.error('Speech Recognition Error:', error);
		};

		recognition.onend = () => {
			setIsListening(false);
		};

		recognition.start();
	};

	const sendCommandToServer = (command: string) => {
		const protocol = window.location.protocol === 'https:' ? 'https' : 'http';
		const backendUrl = `${protocol}://${window.location.hostname}:${window.location.port}/speech`;

		fetch(backendUrl, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({ command: command })
		})
			.then(response => response.json())
			.then(data => {
				console.log('Server Response:', data);
			})
			.catch(error => {
				console.error('Error sending command:', error);
			});
	};

	return (
		<button className="custom-button" onClick={handleVoiceCommand} disabled={isListening}>
			{isListening ? 'Listening...' : 'Activate Voice Control'}
		</button>
	);
};

export default VoiceCommandButton;

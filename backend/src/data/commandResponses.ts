// File: backend/src/data/commandResponses.ts

export const commandTTSMap: Record<string, string[]> = {
	'volume/up': [
		"It's time to rock, motherfucker",
		'Turning it up to 11.',
		'Volume boosted.',
		"Let's get loud!"
	],
	'volume/down': ['Bringing the volume down.', 'Turning it down a notch.', 'Shh... quiet time.'],
	mute: ['Silencing the noise.', 'Muted. Peace and quiet.', 'Your ears are safe—for now.'],
	lock: ['Time to take a nap.', 'Locking things down.', 'Goodbye for now.'],
	shutdown: [
		'Goodnight, sweet prince.',
		'Shutting everything down.',
		'See you on the other side.'
	],
	toggle: ['Play or pause—your choice.', 'Toggling playback.', 'Let the music decide.']
};

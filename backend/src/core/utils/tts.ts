// File: backend/src/utils/tts.ts

import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function speak(text: string): Promise<void> {
	const clean = text.replace(/[^a-zA-Z0-9 .,!?'"]/g, '');
	const command = `espeak "${clean}"`;

	try {
		await execAsync(command);
	} catch (err) {
		throw new Error(`TTS failed: ${(err as Error).message}`);
	}
}

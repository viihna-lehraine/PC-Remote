// File: backend/src/utils/sops.ts

import { spawn } from 'node:child_process';
import { env } from '../core/index.js';

export async function decryptSopsFile<T = unknown>(filepath: string): Promise<T> {
	const jsonStr = await new Promise<string>((resolve, reject) => {
		const proc = spawn('sops', [
			'--decrypt',
			'--input-type',
			'json',
			'--output-type',
			'json',
			'--config',
			env.SOPS_CONFIG,
			filepath
		]);

		let output = '';
		let error = '';

		proc.stdout.on('data', chunk => (output += chunk));
		proc.stderr.on('data', chunk => (error += chunk));

		proc.on('close', code => {
			if (code !== 0) {
				return reject(new Error(error.trim() || `sops exited with code ${code}`));
			}
			resolve(output);
		});
	});

	try {
		return JSON.parse(jsonStr) as T;
	} catch (err) {
		throw new Error(`Failed to parse JSON from ${filepath}: ${(err as Error).message}`);
	}
}

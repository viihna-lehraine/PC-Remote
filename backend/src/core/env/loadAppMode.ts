// File: backend/src/core/env/loadAppMode.ts

import { AppMode } from '../../types/index.js';
import fs from 'fs';
import { absolutePaths } from '../../data/paths.js';

const filePath = absolutePaths.appModeEnv;

const loadAppMode = (filePath: string): AppMode => {
	try {
		if (!fs.existsSync(filePath)) {
			throw new Error(`.env file not found at ${filePath}`);
		}

		const rawEnvVars = fs
			.readFileSync(filePath, 'utf-8')
			.split('\n')
			.filter(line => line.trim() && !line.startsWith('#'));

		// Extract the value of APP_MODE
		const appModeLine = rawEnvVars.find(line => line.startsWith('APP_MODE=')); // Looking for 'APP_MODE' definition
		if (!appModeLine) {
			throw new Error(`APP_MODE not defined in the file ${filePath}`);
		}

		const appModeValue = appModeLine.split('=')[1].trim();
		return appModeValue as AppMode;
	} catch (error) {
		console.error(`Error loading APP_MODE: ${error instanceof Error ? error.message : error}`);
		process.exit(1);
	}
};

export const appMode = loadAppMode(filePath);

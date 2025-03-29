// File: backend/src/utils/sanitize.ts

import { SanitationUtils } from '../../types/index.js';
import sanitizeHtml from 'sanitize-html';

function html(userInput: string): string {
	return sanitizeHtml(userInput);
}

export const sanitize: SanitationUtils = {
	html
};

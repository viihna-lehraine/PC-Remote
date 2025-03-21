// File: backend/src/core/logging.ts

import { FastifyBaseLogger } from 'fastify';

export function patchConsole(log: FastifyBaseLogger): void {
	console.log = (...args) => log.info(args.join(' '));
	console.warn = (...args) => log.warn(args.join(' '));
	console.error = (...args) => log.error(args.join(' '));
	console.debug = (...args) => log.debug(args.join(' '));
}

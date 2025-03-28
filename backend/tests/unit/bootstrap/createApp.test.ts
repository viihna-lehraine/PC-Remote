// File: backend/test/unit/bootstrap/createApp.test.ts

import { AppMode } from '../../../src/types/index.js';
import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { describe, it, expect, vi } from 'vitest';
import supertest from 'supertest';
import { createApp } from '../../../src/bootstrap/createApp.js';
import { env } from '../../../src/core/index.js';
import * as fs from 'fs';
import { appMode } from '../../../src/core/env/index.js';

vi.mock('fs', () => ({
	__esModule: true,
	existsSync: vi.fn().mockReturnValue(true),
	readFileSync: vi.fn().mockReturnValue('APP_MODE=dev')
}));

// @ts-ignore // TODO: Fix this type error
vi.spyOn(process, 'exit').mockImplementation((code?: string | number | undefined | null) => {});

// describe block to group tests related to the app creation
describe('createApp', () => {
	it('should initialize the app with proper logging configuration', async () => {
		const app = createApp();
		app.get('/test', async (request, reply) => {
			return { message: 'Hello World' };
		});

		const response = await supertest(app.server).get('/test');
		expect(response.status).toBe(200);
		expect(response.body.message).toBe('Hello World');
	});

	it('should call fs.mkdirSync to create log directory', () => {
		createApp();
		expect(fs.mkdirSync).toHaveBeenCalledWith(env.LOG_DIR, { recursive: true });
	});

	it('should configure logger with file and console transport', () => {
		const app = createApp();
		const loggerConfig = app.log.transport;
		expect(loggerConfig[0].target).toBe('pino/file');
		expect(loggerConfig[1].target).toBe('pino-pretty');
	});
});

it('should return a 404 if the directory does not exist', async () => {
	const app = createApp();

	// make sure to mock fs.existsSync to simulate a missing directory
	vi.spyOn(fs, 'existsSync').mockReturnValue(false);

	// simulate a request to a non-existing directory
	const response = await supertest(app.server).get('/test/non-existing-directory');
	expect(response.status).toBe(404);
	expect(response.text).toContain('Directory not found');
});

// it('should handle invalid file paths gracefully', async () => {
// 	const app = createApp();
//
// 	// mock fs.readFile to simulate an invalid path
// 	vi.spyOn(fs, 'readFile').mockImplementation(
// 		(
// 			path: string,
// 			encoding: string | null,
// 			options: any,
// 			callback: (err: Error | null, data: string | Buffer | null) => void
// 		) => {
// 			// Simulate an error (e.g., file not found)
// 			callback(new Error('ENOENT: no such file or directory'), null);
// 		}
// 	);
//
// 	const response = await supertest(app.server).get('/test/invalid-path');
// 	expect(response.status).toBe(500);
// 	expect(response.body.error).toBe('Error reading directory');
// });

it('should ensure the log directory exists', async () => {
	const app = createApp();
	expect(fs.mkdirSync).toHaveBeenCalledWith(env.LOG_DIR, { recursive: true });
});

it('should log errors to the log file', async () => {
	const app = createApp();
	const logSpy = vi.spyOn(app.log, 'info');

	// simulate an error to trigger a log
	app.log.info('Testing log');
	expect(logSpy).toHaveBeenCalledWith('Testing log');
});

it('should have custom headers set', async () => {
	const app = createApp();
	app.get('/custom-header', async (request: FastifyRequest, reply: FastifyReply) => {
		reply.header('x-custom-header', '123');
		return 'hello';
	});

	const response = await supertest(app.server).get('/custom-header');
	expect(response.header['x-custom-header']).toBe('123');
});

it('should return a 500 for an unexpected error', async () => {
	const app = createApp();

	// Mock an error in the file reading logic
	vi.spyOn(fs, 'readdir').mockImplementationOnce(() => {
		throw new Error('Unexpected error');
	});

	const response = await supertest(app.server).get('/test');
	expect(response.status).toBe(500);
	expect(response.body.error).toBe('Internal Server Error');
});

it('should not allow access to restricted files', async () => {
	const app = createApp();

	// Simulate attempting to access a restricted file
	const response = await supertest(app.server).get('/test/etc/passwd');

	expect(response.status).toBe(403); // Forbidden
	expect(response.body.error).toBe('Forbidden');
});

it('should return a 400 error for invalid path input', async () => {
	const app = createApp();

	const response = await supertest(app.server).get('/test/invalid-path/|');
	expect(response.status).toBe(400); // Bad Request
	expect(response.body.error).toBe('Invalid path');
});

// it('should cache directory listings', async () => {
// 	const app = createApp();
//
// 	// simulate caching by making a request and checking the response
// 	const firstResponse = await supertest(app.server).get('/test/some-directory');
// 	const secondResponse = await supertest(app.server).get('/test/some-directory');
//
// 	// assuming the cache is set correctly, the second request should be faster (or same)
// 	expect(firstResponse.status).toBe(200);
// 	expect(secondResponse.status).toBe(200);
// 	expect(firstResponse.body).toEqual(secondResponse.body); // Same content
// });

// File: backend/src/plugins/session.ts

import { SecureSessionPluginOptions } from '../types/index.js';
import fp from 'fastify-plugin';
import { FastifyPluginCallback } from 'fastify';
import secureSession from '@fastify/secure-session';
import { getSessionSecret } from '../services/vaultClient.js';

export default fp(async function (fastify) {
	try {
		console.log('Registering Session plugin');

		console.log(`Retrieving Session secret`);
		const key = await getSessionSecret();

		const sessionOptions: SecureSessionPluginOptions = {
			key,
			cookie: {
				path: '/',
				httpOnly: true,
				sameSite: 'strict',
				secure: true
			}
		};

		fastify.register(
			secureSession as FastifyPluginCallback<SecureSessionPluginOptions>,
			sessionOptions
		);

		console.log('Session plugin registered successfully');
	} catch (error) {
		console.error('Error registering session plugin:', error);
		throw new Error('Failed to register session plugin');
	}
});

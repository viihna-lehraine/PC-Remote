// File: backend/src/plugins/staticFiles.ts

import fastifyStatic from '@fastify/static';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import fs from 'fs';
import { regex } from '../data/regex.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function registerStaticFiles(app: FastifyInstance): void {
	app.register(fastifyStatic, {
		root: join(__dirname, '../../../frontend/public/assets'),
		prefix: '/assets',
		decorateReply: false,
		setHeaders: (res, path) => {
			if (path.endsWith('.css')) {
				res.setHeader('Content-Type', 'text/css');
			} else if (path.endsWith('.js')) {
				res.setHeader('Content-Type', 'application/javascript');
			}
		}
	});

	app.register(fastifyStatic, {
		root: join(__dirname, '../../../frontend/public/static'),
		prefix: '/static',
		decorateReply: false
	});

	app.get('/', (_request: FastifyRequest, reply: FastifyReply) => {
		const indexHtmlPath = join(__dirname, '../../../frontend/public/index.html');

		fs.readFile(indexHtmlPath, 'utf8', (err, data) => {
			if (err) {
				console.error('Failed to read index.html:', err);
				reply.status(500).send({ error: 'Failed to load index.html' });
				return;
			}

			const cssMatch = data.match(/href="\/assets\/(index-[\w\d]+\.css)"/);
			const jsMatch = data.match(/src="\/assets\/(index-[\w\d]+\.js)"/);

			if (!cssMatch || !jsMatch) {
				console.error('CSS or JS file not found in index.html');
				reply.status(500).send({ error: 'Failed to find CSS or JS file in index.html' });
				return;
			}

			const cssFile = `/assets/${cssMatch[1]}`;
			const jsFile = `/assets/${jsMatch[1]}`;

			const modifiedHtml = data
				.replace(regex.css, `<link rel="stylesheet" href="${cssFile}">`)
				.replace(regex.js, `<script src="${jsFile}"></script>`);

			reply.type('text/html').send(modifiedHtml);
		});
	});
}

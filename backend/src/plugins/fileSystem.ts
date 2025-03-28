// File: backend/src/plugins/fileSystem.ts

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import fs from 'fs';
import path from 'path';

interface FileQuery {
	path?: string;
}

async function fsPlugin(fastify: FastifyInstance) {
	fastify.get(
		'/api/files',
		async (request: FastifyRequest<{ Querystring: FileQuery }>, reply: FastifyReply) => {
			const dirPath = request.query.path || '/';

			try {
				const resolvedPath = path.resolve(path.join(__dirname, dirPath));
				console.log('Resolved Path:', resolvedPath); // Debugging

				if (!fs.existsSync(resolvedPath)) {
					console.error('Directory not found:', resolvedPath);
					return reply.status(404).send({ error: 'Directory not found' });
				}

				const files = await new Promise<{ name: string; type: 'file' | 'directory' }[]>(
					(resolve, reject) => {
						fs.readdir(resolvedPath, { withFileTypes: true }, (err, files) => {
							if (err) {
								console.error('Error reading directory:', err); // Log error details
								reject('Failed to read directory');
							} else {
								resolve(
									files.map(file => ({
										name: file.name,
										type: file.isDirectory() ? 'directory' : 'file'
									}))
								);
							}
						});
					}
				);

				reply.send(files);
			} catch (err) {
				console.error('Error fetching files:', err);
				reply.status(500).send({ error: err });
			}
		}
	);

	fastify.get(
		'/api/file',
		async (request: FastifyRequest<{ Querystring: FileQuery }>, reply: FastifyReply) => {
			const filePath = request.query.path;

			if (!filePath) {
				return reply.status(400).send({ error: 'No file path provided' });
			}

			try {
				const resolvedFilePath = path.resolve(path.join(__dirname, filePath));
				if (!fs.existsSync(resolvedFilePath)) {
					return reply.status(404).send({ error: 'File not found' });
				}

				const data = await new Promise<string>((resolve, reject) => {
					fs.readFile(resolvedFilePath, 'utf8', (err, data) => {
						if (err) {
							console.error('Error reading file:', err); // Log error details
							reject('Failed to read file');
						} else {
							resolve(data);
						}
					});
				});

				reply.send(data);
			} catch (err) {
				console.error('Error reading file:', err);
				reply.status(500).send({ error: err instanceof Error ? err.message : err });
			}
		}
	);
}

export default fsPlugin;

// File: backend/src/routes/admin.ts

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import fs from 'fs';
import path, { dirname } from 'path';
import { fileURLToPath } from 'url';
import argon2 from 'argon2';
import Database from 'better-sqlite3';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const dbPath = path.join(__dirname, '../db/sqLite/db.sqlite');

const db = new Database(dbPath);

export async function registerAdminPanel(app: FastifyInstance) {
	app.get('/admin', async (_request: FastifyRequest, reply: FastifyReply) => {
		const htmlContent = `
      	<html>
        <head><title>ADMIN PANEL: File Browser</title></head>
        	<body>
				<h1>Admin Panel</h1>

				<h2>Set Admin Password</h2>
    			<form method="POST" action="/admin/set-password">
    			  <label for="password">New Password:</label>
    			  <input type="password" id="password" name="password" required />
    			  <button type="submit">Set Password</button>
    			</form>

				<h2>Login</h2>
    			<form method="POST" action="/admin-login">
    			  <label for="password">Password:</label>
    			  <input type="password" id="password" name="password" required />
    			  <button type="submit">Login</button>
    			</form>

				<script>
      				//
    			</script>


        		<h2>File Browser</h2>
        			<form method="GET" action="/admin/files">
        				<label for="path">Enter Path:</label>
        				<input type="text" id="path" name="path" value="/" />
        				<button type="submit">Navigate</button>
        	  		</form>
        	  	<h2>Files</h2>
        	  	<div id="files">
        	    <!-- Files will be displayed here -->
        	  	</div>
        	  	<script>
        	    // Fetch files on page load based on current path
        	    	const queryParams = new URLSearchParams(window.location.search);
        	    	const path = queryParams.get('path') || '/';
        	    	fetch(\`/admin/files?path=\${path}\`)
        	      		.then(response => response.json())
        	      		.then(files => {
        	        		const filesList = document.getElementById('files');
        	        		filesList.innerHTML = ''; // Clear existing list
        	        		files.forEach(file => {
        	          			const fileDiv = document.createElement('div');
        	          			fileDiv.innerHTML = \`\${file.type === 'directory' ? '📂' : '📄'} \${file.name}\`;
        	          			fileDiv.onclick = () => navigateTo(file);
        	          			filesList.appendChild(fileDiv);
        	        		});
        	      		})
        	    	.catch(err => {
        	    		console.error('Error loading files:', err);
        	    	});

        	    	// Navigate to clicked directory or file
        	    	function navigateTo(file) {
        	      		const newPath = \`\${window.location.origin}/admin?path=\${encodeURIComponent(path + '/' + file.name)}\`;
        	      		window.location.href = newPath;
        	    	}
        	  	</script>
        	</body>
      	</html>
    `;

		reply.type('text/html').send(htmlContent);
	});

	app.get(
		'/admin/files',
		async (
			request: FastifyRequest<{ Querystring: { path?: string } }>,
			reply: FastifyReply
		) => {
			const dirPath = request.query.path || '/';
			const resolvedPath = path.resolve(__dirname, dirPath); // Resolve path to avoid security issues

			// Check if the directory exists
			if (!fs.existsSync(resolvedPath)) {
				return reply.status(404).send('Directory not found');
			}

			try {
				const files = await new Promise<{ name: string; type: 'file' | 'directory' }[]>(
					(resolve, reject) => {
						fs.readdir(resolvedPath, { withFileTypes: true }, (err, files) => {
							if (err) {
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

				// Send the files as a response
				reply.send(files);
			} catch (error) {
				console.error('Error fetching files:', error);
				reply.status(500).send('Error reading directory');
			}
		}
	);

	app.post('/admin/set-password', async (request: FastifyRequest, reply: FastifyReply) => {
		const { password } = request.body as { password: string };

		// Hash the new password
		const hashedPassword = await argon2.hash(password);

		try {
			// Store the hashed password in the database (or update if it exists)
			const stmt = db.prepare(
				'INSERT INTO users (username, password) VALUES (?, ?) ON CONFLICT(username) DO UPDATE SET password = ?'
			);
			stmt.run('admin', hashedPassword, hashedPassword);

			reply.send({ message: 'Password set successfully' });
		} catch (error) {
			console.error('Error setting password:', error);
			reply.status(500).send({ error: 'Failed to set password' });
		}
	});

	app.post('/admin-login', async (request: FastifyRequest, reply: FastifyReply) => {
		(request.session as { set(key: string, value: unknown): void }).set('user', {
			id: 1,
			username: 'admin'
		});

		reply.send({ message: 'Logged in as admin' });
	});

	app.post('/admin-logout', async (request: FastifyRequest, reply: FastifyReply) => {
		(request.session as { delete(): void }).delete();

		reply.send({ message: 'Logged out' });
	});
}

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const sslCert = fs.readFileSync(path.resolve(__dirname, '../backend/config/tls/server.crt'));
const sslKey = fs.readFileSync(path.resolve(__dirname, '../backend/config/tls/server.key'));

export default defineConfig({
	root: 'src',
	publicDir: '../public',
	build: {
		outDir: '../dist',
		emptyOutDir: true
	},
	plugins: [react()],
	server: {
		cors: true,
		host: '192.168.50.10',
		https: {
			key: sslKey,
			cert: sslCert
		},
		open: true,
		port: 3070,
		proxy: {
			'/api': {
				target: 'http://localhost:3050',
				changeOrigin: true,
				secure: false
			}
		},
		strictPort: true
	}
});

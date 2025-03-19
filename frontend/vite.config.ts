import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';

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

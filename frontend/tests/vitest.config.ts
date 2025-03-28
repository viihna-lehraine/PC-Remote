import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react-swc';

export default defineConfig({
	plugins: [react()],
	test: {
		globals: true,
		environment: 'jsdom',
		setupFiles: './setup.ts',
		coverage: {
			provider: 'v8',
			reporter: ['text', 'json', 'html'],
			include: ['../src/**/*.tsx', '../src/**/*.ts'],
			exclude: ['node_modules', 'tests']
		}
	}
});

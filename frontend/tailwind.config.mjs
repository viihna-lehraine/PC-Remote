// File: frontend/tailwind.config.mjs

/** @type {import('tailwindcss').Config} */

export default {
	content: ['./src/index.html', './src/**/*.{js,ts,jsx,tsx}'],
	safelist: [],
	theme: {
		extend: {
			keyframes: {
				scrollText: {
					'0%': { transform: 'translateX(100%)' },
					'100%': { transform: 'translateX(-100%)' }
				}
			},
			animation: {
				scroll: 'scrollText 12s linear infinite'
			},
			colors: {}
		}
	},
	plugins: []
};

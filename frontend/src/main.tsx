// File: frontend/src/main.tsx

import React from 'react';
import ReactDOM from 'react-dom/client';
import WrappedApp from './App.js';
import './styles/index.css';

const root = ReactDOM.createRoot(document.getElementById('root') as HTMLElement);
root.render(
	<React.StrictMode>
		<WrappedApp />
	</React.StrictMode>
);

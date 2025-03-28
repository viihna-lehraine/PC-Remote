// File: frontend/src/react/components/FileBrowser.tsx

import { useState, useEffect } from 'react';

// Define the type for a file
interface File {
	name: string;
	type: 'file' | 'directory';
}

const FileBrowser = () => {
	const [currentPath, setCurrentPath] = useState<string>('/');
	const [files, setFiles] = useState<File[]>([]);
	const [loading, setLoading] = useState<boolean>(false);
	const [isOverlayOpen, setIsOverlayOpen] = useState<boolean>(false); // To manage overlay visibility

	// Fetch files for the current path
	const fetchFiles = (path: string) => {
		setLoading(true);

		const protocol = window.location.protocol === 'https:' ? 'https' : 'http';
		const backendUrl = `${protocol}://${
			window.location.hostname
		}:3060/api/files?path=${encodeURIComponent(path)}`;

		fetch(backendUrl)
			.then(response => response.json())
			.then((data: File[]) => {
				setFiles(data);
				setLoading(false);
			})
			.catch(err => {
				console.error('Error fetching files:', err);
				setLoading(false);
			});
	};

	// Navigate to a subdirectory or go back to the parent directory
	const handleNavigate = (fileName: string, isDirectory: boolean) => {
		if (isDirectory) {
			const newPath = `${currentPath}/${fileName}`;
			setCurrentPath(newPath);
		}
	};

	// Go back to the parent directory
	const handleGoBack = () => {
		const parentDir = currentPath.substring(0, currentPath.lastIndexOf('/')) || '/';
		setCurrentPath(parentDir);
	};

	// Open/Close the overlay
	const toggleOverlay = () => {
		setIsOverlayOpen(!isOverlayOpen);
	};

	// Fetch files when currentPath changes
	useEffect(() => {
		fetchFiles(currentPath);
	}, [currentPath]);

	return (
		<div>
			{/* Button to toggle the File Browser overlay */}
			<button
				onClick={toggleOverlay}
				className="fixed bottom-4 right-4 bg-blue-600 text-white p-4 rounded-full shadow-xl z-50 hover:bg-blue-500 transition-all"
			>
				📂 Open File Browser
			</button>

			{/* Overlay for the file browser */}
			{isOverlayOpen && (
				<div
					className="fixed inset-0 bg-gray-900 bg-opacity-80 z-40 flex items-center justify-center"
					style={{ overflowY: 'auto' }}
				>
					<div className="file-browser-container bg-gray-800 text-white rounded-lg p-6 max-w-4xl mx-auto shadow-lg">
						{/* Close button */}
						<button
							onClick={toggleOverlay}
							className="absolute top-4 right-4 text-white text-xl"
						>
							✖️
						</button>

						{/* Breadcrumbs */}
						<div className="breadcrumbs flex items-center gap-3 mb-6 text-sm text-gray-400">
							<button
								onClick={handleGoBack}
								disabled={currentPath === '/'}
								className="back-button text-blue-500 hover:text-blue-400 disabled:text-gray-500"
							>
								⬅️ Back
							</button>
							<span>{currentPath}</span>
						</div>

						{/* Loading State */}
						{loading ? (
							<div>Loading...</div>
						) : (
							<div>
								{files.map(file => (
									<div key={file.name}>
										<div
											onClick={() =>
												handleNavigate(file.name, file.type === 'directory')
											}
											style={{
												cursor: 'pointer',
												padding: '5px',
												margin: '2px',
												backgroundColor:
													file.type === 'directory'
														? 'lightgreen'
														: 'lightgray'
											}}
										>
											{file.type === 'directory' ? '📂' : '📄'} {file.name}
										</div>
									</div>
								))}
							</div>
						)}
					</div>
				</div>
			)}
		</div>
	);
};

export default FileBrowser;

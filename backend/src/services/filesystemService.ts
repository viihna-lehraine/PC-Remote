// File: backend/src/services/filesystemService.ts

import { FileEntry, Role } from '../types/index.js';
import { mediaExts } from '../data/exts.js';
import fs from 'node:fs/promises';
import path from 'node:path';
import { RBAC_DIRECTORY_WHITELIST } from '../config/filesystem.js';

export async function listDirectory(userRole: Role, relPath: string): Promise<FileEntry[]> {
	const allowedRoots = RBAC_DIRECTORY_WHITELIST[userRole];
	if (!allowedRoots?.length) throw new Error('Access denied');

	const target = path.resolve('/', relPath);
	const isAllowed = allowedRoots.some(root => target.startsWith(path.resolve(root)));

	if (!isAllowed) throw new Error('Access outside allowed scope');

	const entries = await fs.readdir(target, { withFileTypes: true });

	return entries.map(entry => {
		const full = path.join(target, entry.name);
		const ext = path.extname(entry.name).toLowerCase();
		const type = entry.isDirectory() ? 'directory' : 'file';

		const foundType = Object.entries(mediaExts).find(([__, exts]) => exts.includes(ext));
		const mediaType = (foundType?.[0] as FileEntry['mediaType']) || undefined;

		const fileEntry: FileEntry = {
			name: entry.name,
			fullPath: full,
			type
		};

		if (mediaType) {
			fileEntry.mediaType = mediaType;
		}

		return fileEntry;
	});
}

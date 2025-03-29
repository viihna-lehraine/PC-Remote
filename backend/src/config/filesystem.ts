// File: backend/src/config/filesystem.ts

export const RBAC_DIRECTORY_WHITELIST = {
	admin: ['/home/viihna'],
	trusted_user: [
		'/home/viihna/Downloads',
		'/home/viihna/Pictures',
		'/home/viihna/Projects',
		'/home/viihna/Videos'
	],
	user: ['/home/viihna/Downloads/shared'],
	guest: ['']
} satisfies Record<string, string[]>;

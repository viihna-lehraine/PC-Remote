// File: backend/src/types/db.ts

export interface Permission {
	id: number;
	name: string;
	description: string | null;
}

export interface Role {
	id: number;
	name: string;
	description: string | null;
}

export interface RolePermission {
	role_id: number;
	permission_id: number;
}

export interface User {
	id: number;
	name: string;
	password_hash: string;
	email: string | null;
	created_at: string;
}

export interface UserRole {
	user_id: number;
	role_id: number;
}

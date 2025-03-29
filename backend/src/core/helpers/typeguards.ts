// File: backend/src/core/helpers/typeguards.ts

import { Role } from '../../types/index.js';

const isRole = (value: string): value is Role => {
	return ['admin', 'truster_user', 'user', 'guest'].includes(value);
};

export const typeguards = {
	isRole
};

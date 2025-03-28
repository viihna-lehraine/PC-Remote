// File: backend/src/core/errors/errorClasses.ts

export class AppError extends Error {
	public statusCode: number;

	constructor(message: string, statusCode: number = 500) {
		super(message);
		this.statusCode = statusCode;

		Error.captureStackTrace(this, this.constructor);
	}
}

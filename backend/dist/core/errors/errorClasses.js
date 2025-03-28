// File: backend/src/core/errors/errorClasses.ts
export class AppError extends Error {
    statusCode;
    constructor(message, statusCode = 500) {
        super(message);
        this.statusCode = statusCode;
        Error.captureStackTrace(this, this.constructor);
    }
}
//# sourceMappingURL=errorClasses.js.map
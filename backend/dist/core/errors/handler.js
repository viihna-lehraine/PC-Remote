// File: backend/src/core/errors/errorHandler.ts
import { AppError } from './errorClasses.js';
export const globalErrorHandler = (app) => {
    app.setErrorHandler((error, _req, reply) => {
        const statusCode = error instanceof AppError ? error.statusCode : 500;
        console.error(`[ERROR] ${error.message}`, { stack: error.stack });
        reply.status(statusCode).send({
            success: false,
            error: error.name || 'InternalServerError',
            message: error.message || 'Something went wrong',
            statusCode
        });
    });
    console.log('Global error handler registered');
};
//# sourceMappingURL=handler.js.map
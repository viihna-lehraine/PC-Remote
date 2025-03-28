// File: backend/src/bootstrap/startServer.ts
import { globalErrorHandler } from '../core/index.js';
export async function startServer(app, port, host) {
    try {
        globalErrorHandler(app);
        await app.listen({ port, host });
        console.log(`Server running at http://${host}:${port}`);
    }
    catch (err) {
        app.log.error(err);
        process.exit(1);
    }
}
//# sourceMappingURL=startServer.js.map
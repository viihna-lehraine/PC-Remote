// File: backend/src/server.ts
import Fastify from 'fastify';
import fastifyStatic from '@fastify/static';
import fs from 'fs';
import { globalErrorHandler } from './core/index.js';
import { fileURLToPath } from 'url';
import { join } from 'path';
import path from 'path';
import { env } from './core/index.js';
fs.mkdirSync(env.LOG_DIR, { recursive: true });
const logFilePath = path.join(env.LOG_DIR, 'shoutshack.log');
const app = Fastify({
    logger: {
        level: env.LOG_LEVEL || 'info',
        transport: {
            targets: [
                {
                    target: 'pino/file',
                    options: { destination: logFilePath, mkdir: true }
                },
                {
                    target: 'pino-pretty',
                    options: { colorize: true, translateTime: 'SYS:standard' }
                }
            ]
        }
    }
});
console.log = (...args) => app.log.info(args.join(' '));
console.warn = (...args) => app.log.warn(args.join(' '));
console.error = (...args) => app.log.error(args.join(' '));
console.debug = (...args) => app.log.debug(args.join(' '));
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
app.register(fastifyStatic, {
    root: join(__dirname, '../../frontend/public'),
    prefix: '/'
});
const start = async () => {
    try {
        globalErrorHandler(app);
        await app.listen({ port: env.BACKEND_PORT, host: `${env.LISTEN_ADDR}` });
        console.log(`Server running at http://${env.LAN_IP_ADDR}:${env.BACKEND_PORT}`);
    }
    catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};
start();
await import('./websocket/ws.js');
//# sourceMappingURL=server.js.map
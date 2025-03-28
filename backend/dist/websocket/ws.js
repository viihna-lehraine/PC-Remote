// File: backend/src/websocket/ws.ts
import { env } from '../core/loadEnv.js';
import { exec } from 'child_process';
import { fileURLToPath } from 'url';
import { createServer } from 'https';
import path from 'path';
import { WebSocketServer } from 'ws';
import fs from 'fs';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const httpsOptions = {
    key: fs.readFileSync(path.join(__dirname, '../../config/tls/server.key')),
    cert: fs.readFileSync(path.join(__dirname, '../../config/tls/server.crt'))
};
const server = createServer(httpsOptions);
const wss = new WebSocketServer({ server });
wss.on('connection', ws => {
    console.log('Client connected to WebSocket');
    ws.on('message', message => {
        const command = message.toString();
        console.log(`Received command: ${command}`);
        if (String(message).startsWith('chat:')) {
            const [, username, chatMessage] = command.split(':');
            const formattedMessage = `${username}: ${chatMessage}`;
            console.log(`💬 Chat Message: ${formattedMessage}`);
            // Broadcast to all clients
            wss.clients.forEach(client => {
                if (client.readyState === ws.OPEN) {
                    client.send(`chat:${formattedMessage}`);
                }
            });
        }
        else {
            let shellCommand = '';
            switch (command) {
                case 'toggle':
                    shellCommand = 'playerctl play-pause';
                    break;
                case 'volume/up':
                    shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ +5%';
                    break;
                case 'volume/down':
                    shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ -5%';
                    break;
                case 'mute':
                    shellCommand = 'pactl set-sink-mute @DEFAULT_SINK@ toggle';
                    break;
                default:
                    console.log('Unknown command:', command);
                    ws.send(`Unknown command: ${command}`);
                    return;
            }
            exec(shellCommand, (error, stdout, stderr) => {
                if (error) {
                    console.error(`Error executing ${command}: ${error.message}`);
                    ws.send(`Error: ${error.message}`);
                    return;
                }
                console.log(`Command executed: ${command}`);
                console.log(`Output: ${stdout}`);
                if (stderr)
                    console.error(`Stderr: ${stderr}`);
                ws.send(`Executed: ${command}`);
            });
        }
    });
    ws.on('close', () => console.log('Client disconnected'));
});
server.listen(env.WS_PORT, env.LISTEN_ADDR, () => {
    console.log(`WebSocket server running on wss://${env.LAN_IP_ADDR}:${env.WS_PORT}`);
});
//# sourceMappingURL=ws.js.map
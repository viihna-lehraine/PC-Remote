// File: backend/src/websocket/ws.ts
import { env } from '../core/loadEnv.js';
import { exec } from 'child_process';
import { WebSocketServer } from 'ws';
try {
    const wss = new WebSocketServer({ port: env.WS_PORT, host: `${env.LISTEN_ADDR}` });
    wss.on('connection', ws => {
        console.log('Client connected to WebSocket');
        ws.on('message', message => {
            const command = message.toString();
            console.log(`Received command: ${command}`);
            if (String(message).startsWith('chat:')) {
                const [, username, chatMessage] = command.split(':');
                const formattedMessage = `${username}: ${chatMessage}`;
                console.log(`💬 Chat Message: ${formattedMessage}`);
                // broadcast to all clients
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
    console.log(`WebSocket server running on ws://${env.LAN_IP_ADDR}:${env.WS_PORT}`);
}
catch (error) {
    console.error(`WebSocket Server Error: ${error.message}`);
    process.exit(1);
}
//# sourceMappingURL=ws.js.map
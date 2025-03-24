// File: backend/src/ws/commands.ts
import { exec } from 'child_process';
export function handleCommandSocket(ws, command) {
    let shellCommand = '';
    switch (command) {
        case 'lock':
            shellCommand = 'systemctl suspend';
            break;
        case 'mute':
            shellCommand = 'pactl set-sink-mute @DEFAULT_SINK@ toggle';
            break;
        case 'shutdown':
            shellCommand = 'shutdown -h now';
            break;
        case 'toggle':
            shellCommand = 'playerctl play-pause';
            break;
        case 'volume/up':
            shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ +5%';
            break;
        case 'volume/down':
            shellCommand = 'pactl set-sink-volume @DEFAULT_SINK@ -5%';
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
//# sourceMappingURL=commands.js.map
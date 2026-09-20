const { Client } = require('ssh2');

const HOST = '164.52.213.44';
const USERNAME = 'royalninja';
const PASSWORD = 'ZvDOxmg6nXNNctRsx1Y6';

function execCommand(conn, cmd) {
    return new Promise((resolve, reject) => {
        console.log(`\n💻 Executing: ${cmd}`);
        conn.exec(cmd, (err, stream) => {
            if (err) return reject(err);
            let stdout = '';
            let stderr = '';
            stream.on('close', (code) => {
                resolve({ code, stdout, stderr });
            }).on('data', (data) => {
                stdout += data.toString();
                process.stdout.write(data);
            }).stderr.on('data', (data) => {
                stderr += data.toString();
                process.stderr.write(data);
            });
        });
    });
}

async function run() {
    const conn = new Client();
    await new Promise((resolve, reject) => {
        conn.on('ready', resolve).on('error', reject).connect({
            host: HOST,
            port: 22,
            username: USERNAME,
            password: PASSWORD
        });
    });

    // Check Nginx configuration or other app configurations
    await execCommand(conn, 'grep -rn "royalninja" /etc/nginx/ /etc/nginx/conf.d/ /etc/nginx/sites-enabled/ /etc/nginx/sites-available/ /usr/local/lsws/ 2>/dev/null || true');
    await execCommand(conn, 'grep -rn "proxy_pass" /etc/nginx/sites-enabled/ /etc/nginx/conf.d/ 2>/dev/null || true');
    await execCommand(conn, 'ps aux | grep -E "nginx|node|pm2" || true');
    await execCommand(conn, 'netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || true');

    conn.end();
}

run().catch(console.error);

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

    // Check where nginx or litespeed or apache configs are stored
    await execCommand(conn, 'ps -ef | grep -E "nginx|litespeed|lsws|httpd|apache" | grep -v grep || true');
    await execCommand(conn, 'cat /etc/nginx/nginx.conf 2>/dev/null || true');
    await execCommand(conn, 'ls -la /etc/nginx/conf.d/ /etc/nginx/sites-enabled/ 2>/dev/null || true');
    await execCommand(conn, 'grep -rn "zodplaygames" /etc/ 2>/dev/null || true');
    await execCommand(conn, 'find /home/zodplaygames-* -maxdepth 3 -name ".htaccess" -o -name "*.conf" 2>/dev/null || true');

    conn.end();
}

run().catch(console.error);

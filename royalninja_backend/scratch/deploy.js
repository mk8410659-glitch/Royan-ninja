const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');

const HOST = '164.52.213.44';
const CREDENTIALS = [
    { username: 'royalninja', password: 'ZvDOxmg6nXNNctRsx1Y6' },
    { username: 'zodplaygames-royalninja', password: 'ZvDOxmg6nXNNctRsx1Y6' },
    { username: 'root', password: 'ZvDOxmg6nXNNctRsx1Y6' }
];

async function tryConnect(cred) {
    return new Promise((resolve, reject) => {
        console.log(`\n🔑 Testing SSH connection as '${cred.username}' on ${HOST}...`);
        const conn = new Client();
        conn.on('ready', () => {
            console.log(`✅ Authentication SUCCESSFUL as '${cred.username}'!`);
            resolve(conn);
        }).on('error', (err) => {
            console.log(`❌ Failed as '${cred.username}': ${err.message}`);
            reject(err);
        }).connect({
            host: HOST,
            port: 22,
            username: cred.username,
            password: cred.password,
            readyTimeout: 10000
        });
    });
}

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

async function main() {
    let conn = null;
    let activeCred = null;
    for (const cred of CREDENTIALS) {
        try {
            conn = await tryConnect(cred);
            activeCred = cred;
            break;
        } catch (e) {
            // try next
        }
    }

    if (!conn) {
        console.error('\n🚨 Could not connect with any of the provided username combinations.');
        process.exit(1);
    }

    // Inspect server environment
    await execCommand(conn, 'whoami && pwd');
    await execCommand(conn, 'ls -la /home /home/* /var/www /var/www/html 2>/dev/null || true');
    await execCommand(conn, 'which node npm pm2 mongo mongod redis-cli 2>/dev/null || true');
    await execCommand(conn, 'node -v; npm -v; pm2 -v 2>/dev/null || true');
    await execCommand(conn, 'pm2 list 2>/dev/null || true');

    conn.end();
}

main().catch(err => {
    console.error('Execution error:', err);
    process.exit(1);
});

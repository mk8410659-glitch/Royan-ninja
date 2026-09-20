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

    // Check sudo privileges
    await execCommand(conn, `echo "${PASSWORD}" | sudo -S -l`);
    // Check curl response details
    await execCommand(conn, 'curl -i https://royalninja.zodplaygames.com/login');
    // If sudo works, view nginx config for royalninja
    await execCommand(conn, `echo "${PASSWORD}" | sudo -S grep -rn "royalninja" /etc/nginx/ /home/clp/ 2>/dev/null || true`);

    conn.end();
}

run().catch(console.error);

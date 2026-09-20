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

    const appDir = '/home/zodplaygames-royalninja/htdocs/royalninja.zodplaygames.com';

    // 1. Update PORT to 3017 in remote .env
    console.log('📝 Updating PORT to 3017 in remote .env...');
    await execCommand(conn, `sed -i 's/PORT=3014/PORT=3017/' ${appDir}/.env`);
    await execCommand(conn, `grep "^PORT=" ${appDir}/.env`);

    // 2. Restart PM2 royalninja
    console.log('🔄 Restarting royalninja in PM2...');
    await execCommand(conn, `pm2 restart royalninja`);
    await execCommand(conn, `pm2 status`);

    // 3. Wait 2 seconds and test local port 3017
    console.log('🧪 Testing local port 3017...');
    await execCommand(conn, `sleep 2 && curl -I http://127.0.0.1:3017/login`);

    // 4. Test live domain
    console.log('🌐 Testing public domain https://royalninja.zodplaygames.com/login ...');
    await execCommand(conn, `curl -I https://royalninja.zodplaygames.com/login`);

    conn.end();
}

run().catch(console.error);

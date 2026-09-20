const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');

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

function uploadFile(conn, localPath, remotePath) {
    return new Promise((resolve, reject) => {
        console.log(`\n📤 Uploading ${localPath} -> ${remotePath}...`);
        conn.sftp((err, sftp) => {
            if (err) return reject(err);

            const readStream = fs.createReadStream(localPath);
            const writeStream = sftp.createWriteStream(remotePath);

            writeStream.on('close', () => {
                console.log(`✅ Upload finished: ${remotePath}`);
                resolve();
            });

            writeStream.on('error', (uploadErr) => {
                console.error(`❌ Upload error:`, uploadErr);
                reject(uploadErr);
            });

            readStream.pipe(writeStream);
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

    const targetDir = '/home/zodplaygames-royalninja/htdocs/royalninja.zodplaygames.com';
    const localScript = path.resolve(__dirname, 'inspect_db_clean.js');
    const remoteScript = `${targetDir}/inspect_db_clean.js`;

    await uploadFile(conn, localScript, remoteScript);
    await execCommand(conn, `cd ${targetDir} && node inspect_db_clean.js && rm -f inspect_db_clean.js`);

    conn.end();
}

run().catch(console.error);

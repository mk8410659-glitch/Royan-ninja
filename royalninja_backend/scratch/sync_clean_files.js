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

function uploadFile(sftp, localPath, remotePath) {
    return new Promise((resolve, reject) => {
        console.log(`\n📤 Uploading ${localPath} -> ${remotePath}...`);
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

    const sftp = await new Promise((resolve, reject) => {
        conn.sftp((err, s) => {
            if (err) return reject(err);
            resolve(s);
        });
    });

    const baseRemote = '/home/zodplaygames-royalninja/htdocs/royalninja.zodplaygames.com';
    const baseLocal = path.resolve(__dirname, '..');

    // Upload modified files
    await uploadFile(sftp, path.join(baseLocal, '.env'), `${baseRemote}/.env`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/routes/mainRoutes.js'), `${baseRemote}/backend/routes/mainRoutes.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/routes/modules/appTrackingRoutes.js'), `${baseRemote}/backend/routes/modules/appTrackingRoutes.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/routes/adminRoutes.js'), `${baseRemote}/backend/routes/adminRoutes.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/routes/integrationRoutes.js'), `${baseRemote}/backend/routes/integrationRoutes.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/routes/modules/diamondCatchRoutes.js'), `${baseRemote}/backend/routes/modules/diamondCatchRoutes.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/routes/modules/dailyChallengeAdminRoutes.js'), `${baseRemote}/backend/routes/modules/dailyChallengeAdminRoutes.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/models/dailyChallengeConfig.js'), `${baseRemote}/backend/admin/models/dailyChallengeConfig.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/middlewares/send-notification-api.js'), `${baseRemote}/backend/admin/middlewares/send-notification-api.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/middlewares/cryptoMiddleware.js'), `${baseRemote}/backend/admin/middlewares/cryptoMiddleware.js`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/views/partials/sidebar.ejs'), `${baseRemote}/backend/admin/views/partials/sidebar.ejs`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/views/diamond-catch/manage.ejs'), `${baseRemote}/backend/admin/views/diamond-catch/manage.ejs`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/views/daily-challenge/manage.ejs'), `${baseRemote}/backend/admin/views/daily-challenge/manage.ejs`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/views/wallet/manage.ejs'), `${baseRemote}/backend/admin/views/wallet/manage.ejs`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/views/s2s-postbacks/manage.ejs'), `${baseRemote}/backend/admin/views/s2s-postbacks/manage.ejs`);
    await uploadFile(sftp, path.join(baseLocal, 'backend/admin/views/api-integrations/manage.ejs'), `${baseRemote}/backend/admin/views/api-integrations/manage.ejs`);

    // Restart PM2 process
    console.log('\n🔄 Restarting PM2 process...');
    await execCommand(conn, 'pm2 restart royalninja --update-env');
    await execCommand(conn, 'pm2 status');

    // Verify live domain
    console.log('\n🌐 Testing live domain...');
    await execCommand(conn, 'sleep 1 && curl -I https://royalninja.zodplaygames.com/login');

    conn.end();
}

run().catch(console.error);

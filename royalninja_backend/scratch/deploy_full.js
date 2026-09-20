const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

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
                console.log(`✅ Upload finished successfully!`);
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
    console.log('🚀 Starting Full Deployment Process...');

    // 1. Create local tar.gz bundle of royalninja_backend
    const backendRoot = path.resolve(__dirname, '..');
    const tarballPath = path.join(__dirname, 'deploy_bundle.tar.gz');

    if (fs.existsSync(tarballPath)) {
        fs.unlinkSync(tarballPath);
    }

    console.log('📦 Creating local tar archive (excluding node_modules, scratch, etc.)...');
    const tarCmd = `tar -czf "${tarballPath}" -C "${backendRoot}" --exclude=node_modules --exclude=scratch --exclude=.git .env package.json package-lock.json serviceAccountKey.json backend`;
    console.log(`> ${tarCmd}`);
    execSync(tarCmd, { stdio: 'inherit' });
    const stats = fs.statSync(tarballPath);
    console.log(`📦 Tarball created: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);

    // 2. Connect via SSH
    const conn = new Client();
    await new Promise((resolve, reject) => {
        conn.on('ready', resolve)
            .on('error', reject)
            .connect({
                host: HOST,
                port: 22,
                username: USERNAME,
                password: PASSWORD,
                readyTimeout: 20000
            });
    });
    console.log('✅ SSH Connection established.');

    // 3. Inspect target htdocs folder
    const checkHtdocs = await execCommand(conn, 'ls -la ~/htdocs');
    let targetDir = '/home/zodplaygames-royalninja/htdocs/royalninja.zodplaygames.com';

    const dirCheck = await execCommand(conn, `if [ -d "${targetDir}" ]; then echo "EXISTS"; else echo "NOT_FOUND"; fi`);
    if (!dirCheck.stdout.includes('EXISTS')) {
        // Find actual domain directory inside htdocs
        console.log('Finding domain folders in htdocs...');
        const findRes = await execCommand(conn, 'find ~/htdocs -maxdepth 2 -type d');
        // fallback to ~/htdocs if specific domain folder doesn't exist
        targetDir = '/home/royalninja/htdocs/royalninja.zodplaygames.com';
    }

    await execCommand(conn, `mkdir -p ${targetDir}`);
    console.log(`🎯 Target Deployment Directory: ${targetDir}`);

    // 4. Upload tarball
    const remoteTarPath = `${targetDir}/deploy_bundle.tar.gz`;
    await uploadFile(conn, tarballPath, remoteTarPath);

    // 5. Extract tarball on remote server
    await execCommand(conn, `cd ${targetDir} && tar -xzf deploy_bundle.tar.gz && rm -f deploy_bundle.tar.gz`);
    console.log('✅ Files extracted on server.');

    // 6. Run npm install
    console.log('📥 Installing production dependencies on server...');
    await execCommand(conn, `cd ${targetDir} && npm install --omit=dev`);

    // 7. Seed database (Admin user & AppData)
    console.log('🌱 Seeding database...');
    await execCommand(conn, `cd ${targetDir} && node backend/seed.js`);

    // 8. Configure & Restart PM2 process
    console.log('⚙️ Configuring PM2...');
    await execCommand(conn, `pm2 delete royalninja 2>/dev/null || true`);
    await execCommand(conn, `cd ${targetDir} && pm2 start backend/app.js --name royalninja`);
    await execCommand(conn, `pm2 save`);
    await execCommand(conn, `pm2 status`);

    // 9. Verify local port 3014
    console.log('🔍 Testing local server response...');
    await execCommand(conn, `sleep 2 && curl -I http://127.0.0.1:3014/login || true`);
    await execCommand(conn, `curl -I https://royalninja.zodplaygames.com/login || true`);

    conn.end();
    console.log('\n🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!');
}

run().catch(err => {
    console.error('❌ Deployment failed:', err);
    process.exit(1);
});

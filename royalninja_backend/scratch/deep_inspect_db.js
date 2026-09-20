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

    const inspectScript = `
        const mongoose = require('mongoose');
        async function check() {
            await mongoose.connect('mongodb://127.0.0.1:27017/royalninja');
            const collections = await mongoose.connection.db.listCollections().toArray();
            console.log('--- COLLECTIONS IN royalninja DB ---');
            for (const c of collections) {
                const count = await mongoose.connection.db.collection(c.name).countDocuments();
                console.log(c.name + ': ' + count);
                
                // Search for "panda" or "diamond" in any document text
                const docs = await mongoose.connection.db.collection(c.name).find({}).limit(50).toArray();
                for (const d of docs) {
                    const str = JSON.stringify(d).toLowerCase();
                    if (str.includes('diamondpanda') || str.includes('diamond_panda') || str.includes('diamond panda') || str.includes('countnreward')) {
                        console.log('⚠️ Found old app name in ' + c.name + ':', str.substring(0, 200));
                    }
                }
            }
            await mongoose.disconnect();
        }
        check().catch(console.error);
    `;

    await execCommand(conn, `node -e "${inspectScript.replace(/\n/g, ' ')}"`);

    conn.end();
}

run().catch(console.error);

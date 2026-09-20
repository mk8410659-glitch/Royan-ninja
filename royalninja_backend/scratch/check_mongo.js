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

    // Check collections in royalninja database
    const mongoScript = `
        const colls = db.getCollectionNames();
        print("Collections: " + colls.join(", "));
        for (const c of colls) {
            const count = db[c].countDocuments();
            print(c + ": " + count + " docs");
        }
    `;
    await execCommand(conn, `mongosh royalninja --quiet --eval '${mongoScript}' || mongo royalninja --quiet --eval '${mongoScript}'`);

    conn.end();
}

run().catch(console.error);

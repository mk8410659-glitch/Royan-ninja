const mongoose = require('mongoose');

async function check() {
    await mongoose.connect('mongodb://127.0.0.1:27017/royalninja');
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('=== COLLECTIONS IN royalninja DB ===');
    for (const c of collections) {
        const count = await mongoose.connection.db.collection(c.name).countDocuments();
        console.log(`- ${c.name}: ${count} docs`);
        
        // Search for any occurrence of panda or diamond in documents
        const docs = await mongoose.connection.db.collection(c.name).find({}).toArray();
        for (const d of docs) {
            const str = JSON.stringify(d).toLowerCase();
            if (str.includes('diamondpanda') || str.includes('diamond_panda') || str.includes('diamond panda') || str.includes('countnreward') || str.includes('count_n_reward')) {
                console.log(`⚠️ MATCH FOUND in ${c.name} (id: ${d._id}):`, str.substring(0, 300));
            }
        }
    }
    console.log('=== DB INSPECTION COMPLETE ===');
    await mongoose.disconnect();
}

check().catch(console.error);

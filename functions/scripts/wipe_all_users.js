const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Try to load serviceAccountKey.json
const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');
let serviceAccount;

if (fs.existsSync(serviceAccountPath)) {
    try {
        serviceAccount = require(serviceAccountPath);
        console.log("🔑 Found serviceAccountKey.json, using it.");
    } catch (e) {
        console.warn("⚠️ Found serviceAccountKey.json but failed to load it:", e.message);
    }
} else {
    console.error("❌ No serviceAccountKey.json found! Cannot wipe data safely.");
    process.exit(1);
}

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: 'lifeguardian-app.firebasestorage.app'
});

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage().bucket();

async function listAllUsers(nextPageToken) {
    // List batch of users, 1000 at a time.
    const listUsersResult = await auth.listUsers(1000, nextPageToken);
    const users = listUsersResult.users.map(userRecord => userRecord.uid);

    if (listUsersResult.pageToken) {
        const nextBatch = await listAllUsers(listUsersResult.pageToken);
        return users.concat(nextBatch);
    }
    return users;
}

async function wipeAll() {
    console.log("🚀 STARTING TOTAL WIPE (User Requested: 0 Users State)...");

    // 1. Delete All Auth Users
    console.log("   Scanning Auth Users...");
    try {
        const allUids = await listAllUsers();
        if (allUids.length > 0) {
            console.log(`   Found ${allUids.length} users in Auth. Deleting...`);
            const chunks = [];
            for (let i = 0; i < allUids.length; i += 1000) {
                chunks.push(allUids.slice(i, i + 1000));
            }
            for (const chunk of chunks) {
                const result = await auth.deleteUsers(chunk);
                console.log(`     - Deleted batch: ${result.successCount} success, ${result.failureCount} failed.`);
                if (result.failureCount > 0) {
                    result.errors.forEach(err => console.error('       Error:', err.error.toJSON()));
                }
            }
        } else {
            console.log("   (No users found in Auth)");
        }
    } catch (e) {
        console.error("❌ Auth deletion error:", e.message);
    }

    // 2. Clear Firestore Collections
    console.log("   Deleting Firestore collections...");
    const collectionsToWipe = ['users', 'groups', 'invite_codes'];

    for (const col of collectionsToWipe) {
        const ref = db.collection(col);
        const snapshot = await ref.limit(1).get(); // Check emptiness
        if (!snapshot.empty) {
            console.log(`     Deleting '${col}' collection...`);
            // Recursive delete is supported in admin SDK v11+ usually, checking docs...
            // Actually explicit recursive delete helper:
            await admin.firestore().recursiveDelete(ref);
            console.log(`     ✅ '${col}' deleted.`);
        } else {
            console.log(`     ('${col}' is already empty)`);
        }
    }

    // 3. Clear Storage
    console.log("   Deleting Storage 'users/' folder...");
    try {
        await storage.deleteFiles({ prefix: 'users/' });
        console.log("   ✅ Storage 'users/' cleared.");
    } catch (e) {
        console.error("❌ Storage deletion error:", e.message);
    }

    console.log("✨ WIPE COMPLETE. System should now have 0 users.");
}

wipeAll().then(() => {
    process.exit(0);
}).catch(e => {
    console.error("Fatal Error:", e);
    process.exit(1);
});

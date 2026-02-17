const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Try to load serviceAccountKey.json if it exists
const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');
let serviceAccount;

if (fs.existsSync(serviceAccountPath)) {
    try {
        serviceAccount = require(serviceAccountPath);
        console.log("🔑 Found serviceAccountKey.json, using it for authentication.");
    } catch (e) {
        console.warn("⚠️ Found serviceAccountKey.json but failed to load it:", e.message);
    }
} else {
    console.log("ℹ️ No serviceAccountKey.json found, trying default credentials...");
}

// Initialize Firebase Admin
try {
    const config = {
        projectId: 'lifeguardian-app',
        storageBucket: 'lifeguardian-app.firebasestorage.app'
    };

    if (serviceAccount) {
        config.credential = admin.credential.cert(serviceAccount);
    }

    admin.initializeApp(config);
} catch (e) {
    console.error("❌ Initialization error:", e.message);
    console.error("👉 Please download a service account key from Firebase Console -> Project Settings -> Service Accounts");
    console.error("👉 Save it as 'functions/serviceAccountKey.json' and run this script again.");
    process.exit(1);
}

const db = admin.firestore();
const storage = admin.storage().bucket();
const auth = admin.auth();

async function isUserInAuth(uid) {
    try {
        await auth.getUser(uid);
        return true;
    } catch (e) {
        if (e.code === 'auth/user-not-found') {
            return false;
        }
        throw e;
    }
}

async function wipeOrphanedData() {
    console.log("🔍 Scanning for orphaned data...");
    let orphanCount = 0;

    // --- 1. Scan Firestore 'users' collection ---
    console.log("   Checking Firestore 'users'...");
    try {
        const usersSnapshot = await db.collection('users').get();
        if (usersSnapshot.empty) {
            console.log("   (Firestore 'users' collection is empty)");
        }

        for (const doc of usersSnapshot.docs) {
            const uid = doc.id;
            const exists = await isUserInAuth(uid);

            if (!exists) {
                console.log(`❌ Found Orphan in Firestore (UID: ${uid}). Deleting...`);
                // Recursive delete
                try {
                    await db.recursiveDelete(doc.ref);
                    console.log(`   ✅ Deleted users/${uid} from Firestore.`);
                } catch (e) {
                    console.log(`   ⚠️ recursiveDelete failed, trying simple delete.`);
                    await doc.ref.delete();
                }
                orphanCount++;
            }
        }
    } catch (e) {
        console.error("❌ Firestore scan error:", e.message);
        if (e.message.includes("credential")) {
            console.error("👉 Make sure you have 'functions/serviceAccountKey.json' OR run 'gcloud auth application-default login'");
        }
        return;
    }

    // --- 2. Scan Storage 'users/' folder ---
    console.log("   Checking Storage 'users/'...");
    try {
        const [files] = await storage.getFiles({ prefix: 'users/' });

        if (files.length === 0) {
            console.log("   (Storage 'users/' folder is empty)");
        } else {
            // Group files by UID (users/{uid}/...)
            const uidSet = new Set();
            files.forEach(file => {
                const parts = file.name.split('/');
                if (parts.length > 1) {
                    uidSet.add(parts[1]); // users/UID/filename
                }
            });

            for (const uid of uidSet) {
                const exists = await isUserInAuth(uid);

                if (!exists) {
                    console.log(`❌ Found Orphan specific files in Storage (UID: ${uid}). Deleting...`);
                    await storage.deleteFiles({ prefix: `users/${uid}/` });
                    console.log(`   ✅ Deleted users/${uid}/* from Storage.`);
                    orphanCount++;
                }
            }
        }

    } catch (e) {
        console.error("❌ Storage scan error:", e.message);
    }

    if (orphanCount === 0) {
        console.log("✨ System Clean! No orphaned data found.");
    } else {
        console.log("🧹 Cleanup Complete.");
    }
}

wipeOrphanedData();

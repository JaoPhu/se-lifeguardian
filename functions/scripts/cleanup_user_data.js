const admin = require('firebase-admin');

// Initialize Firebase Admin
try {
    admin.initializeApp({
        projectId: 'lifeguardian-app',
        storageBucket: 'lifeguardian-app.firebasestorage.app'
    });
} catch (e) {
    console.error("Error initializing app:", e);
    process.exit(1);
}

const db = admin.firestore();
const storage = admin.storage().bucket();

async function cleanupUserData(emailOrUid) {
    if (!emailOrUid) {
        console.log("Usage: node cleanup_user_data.js <email_or_uid>");
        console.error('Please provide an Email or UID as an argument.');
        process.exit(1);
    }

    let uid = emailOrUid;
    let email = '';

    // Check if input looks like an email
    if (emailOrUid.includes('@')) {
        email = emailOrUid;
        console.log(`Searching for user with email: ${email}...`);

        // 1. Try to find UID from Auth (if not deleted yet)
        try {
            const userRecord = await admin.auth().getUserByEmail(email);
            uid = userRecord.uid;
            console.log(`Found UID from Auth: ${uid}`);
        } catch (e) {
            console.log(`User not found in Auth (likely verify deleted). Checking Firestore...`);

            // 2. Try to find UID from Firestore 'users' collection
            const userSnapshot = await db.collection('users').where('email', '==', email).limit(1).get();
            if (!userSnapshot.empty) {
                uid = userSnapshot.docs[0].id;
                console.log(`Found UID from Firestore: ${uid}`);
            } else {
                console.error(`Could not find any user with email: ${email} in Auth or Firestore.`);
                return;
            }
        }
    } else {
        console.log(`Using provided UID: ${uid}`);
    }

    if (!uid) {
        console.error('Could not determine UID. Aborting.');
        return;
    }

    console.log(`Starting cleanup for UID: ${uid}`);

    // --- 1. Delete Firestore Data ---
    const userRef = db.collection('users').doc(uid);

    try {
        console.log('Deleting Firestore data (recursive)...');
        await db.recursiveDelete(userRef);
        console.log('Firestore data deleted.');
    } catch (e) {
        console.error('Error deleting Firestore data:', e);
    }

    // --- 2. Delete Storage Data ---
    // Paths: users/{uid}/*
    const prefix = `users/${uid}/`;
    try {
        console.log(`Deleting Storage files in prefix: ${prefix}...`);
        await storage.deleteFiles({ prefix: prefix });
        console.log('Storage files deleted.');
    } catch (e) {
        console.error('Error deleting Storage files:', e);
    }

    console.log(`Cleanup complete for user: ${uid}`);
}

// Get email/uid from command line argument
const arg = process.argv[2];
cleanupUserData(arg);

const admin = require('firebase-admin');

// Initialize Firebase Admin (Uses Default Credentials or GOOGLE_APPLICATION_CREDENTIALS)
// Ensure you have run: gcloud auth application-default login
// OR: firebase login:ci (and set credential path)
// Best for local dev: export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
try {
    admin.initializeApp();
} catch (e) {
    console.error("Error initializing app. Make sure you have credentials set up.");
    console.error("Try running: gcloud auth application-default login");
    console.error(e);
    process.exit(1);
}

const email = process.argv[2];
const newPassword = process.argv[3];

if (!email || !newPassword) {
    console.log("Usage: node reset_password.js <email> <newPassword>");
    process.exit(1);
}

async function resetPassword() {
    try {
        console.log(`Looking up user: ${email}...`);
        const user = await admin.auth().getUserByEmail(email);
        console.log(`Found user ${user.uid}. Updating password...`);

        await admin.auth().updateUser(user.uid, {
            password: newPassword
        });

        console.log("✅ Password updated successfully!");
        process.exit(0);
    } catch (error) {
        console.error("❌ Error updating password:", error.message);
        process.exit(1);
    }
}

resetPassword();

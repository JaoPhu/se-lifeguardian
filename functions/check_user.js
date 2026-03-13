
const admin = require('firebase-admin');

if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'lifeguardian-app'
    });
}

const db = admin.firestore();

async function checkUser(email) {
    const normalizedEmail = email.trim().toLowerCase();
    console.log(`Checking Firestore for: ${normalizedEmail}`);
    
    try {
        const query = await db.collection('users')
            .where('email', '==', normalizedEmail)
            .get();
        
        if (query.empty) {
            console.log('No user found with that email.');
            // Let's list some users to see the format
            const sample = await db.collection('users').limit(5).get();
            console.log('Sample emails in DB:');
            sample.forEach(doc => {
                console.log(`- ${doc.data().email} (ID: ${doc.id})`);
            });
        } else {
            console.log(`Found ${query.size} user(s).`);
            query.forEach(doc => {
                console.log(`ID: ${doc.id}, Data:`, doc.data());
            });
        }
    } catch (error) {
        console.error('Error:', error);
    }
}

const emailToCheck = process.argv[2] || 'thanapornvisessang@gmail.com';
checkUser(emailToCheck);

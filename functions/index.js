const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateUserPassword = onCall(async (request) => {
    const { email, newPassword } = request.data;

    if (!email || !newPassword) {
        throw new HttpsError('invalid-argument', 'The function must be called with email and newPassword.');
    }

    try {
        const user = await admin.auth().getUserByEmail(email);
        await admin.auth().updateUser(user.uid, {
            password: newPassword,
        });
        return { success: true, message: 'Password updated successfully' };
    } catch (error) {
        console.error('Error updating password:', error);
        throw new HttpsError('internal', 'Error updating password', error.message);
    }
});

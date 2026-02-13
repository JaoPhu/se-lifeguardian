const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

exports.updateUserPassword = onCall({ cors: true }, async (request) => {
    const { email, newPassword } = request.data;

    if (!email || !newPassword) {
        throw new HttpsError('invalid-argument', 'The function must be called with email and newPassword.');
    }

    console.log(`Attempting to update password for email: ${email}`);

    try {
        const user = await admin.auth().getUserByEmail(email);
        await admin.auth().updateUser(user.uid, {
            password: newPassword,
        });
        console.log(`Password updated successfully for UID: ${user.uid} (${email})`);
        return { success: true, message: 'Password updated successfully' };
    } catch (error) {
        console.error('Error in updateUserPassword function:', error);

        // Return specific error messages
        if (error.code === 'auth/user-not-found') {
            throw new HttpsError('not-found', 'ไม่พบอีเมลนี้ในระบบ Auth');
        } else if (error.code === 'auth/weak-password') {
            throw new HttpsError('invalid-argument', 'รหัสผ่านใหม่สั้นเกินไป (ต้อง 6 ตัวขึ้นไป)');
        }

        // Catch other common admin sdk errors if possible
        const errorMessage = error.message || 'Error updating password';
        throw new HttpsError('internal', `Server Error: ${errorMessage}`);
    }
});


exports.sendOTPEmail = onCall(async (request) => {
    const { email, otp } = request.data;

    // Validate input
    if (!email || !otp) {
        throw new HttpsError('invalid-argument', 'Email and OTP are required');
    }

    // Create transporter with Gmail
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: 'lifeguardian.service@gmail.com',
            pass: 'ujnr fgtc pdvw itcj' // App Password
        }
    });

    // Email HTML template
    const htmlContent = `
        <div style="font-family: 'Sarabun', sans-serif; padding: 20px; background-color: #f4f4f4;">
            <div style="max-width: 500px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                <h2 style="color: #0D9488; text-align: center;">รหัสยืนยันตัวตน (OTP)</h2>
                <p style="font-size: 16px; color: #333;">สวัสดีครับ,</p>
                <p style="font-size: 16px; color: #333;">
                    ใช้รหัสอ้างอิงด้านล่างนี้เพื่อยืนยันตัวตนและรีเซ็ตรหัสผ่านของคุณในแอปพลิเคชัน <strong>LifeGuardian</strong>
                </p>
                <div style="text-align: center; margin: 30px 0;">
                    <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #0D9488; background-color: #f0fdfa; padding: 10px 20px; border-radius: 5px; border: 1px solid #ccfbf1;">
                        ${otp}
                    </span>
                </div>
                <p style="font-size: 14px; color: #666; text-align: center;">
                    รหัสนี้จะหมดอายุภายใน 10 นาที<br>
                    หากคุณไม่ได้เป็นผู้ร้องขอ กรุณาเพิกเฉยต่ออีเมลฉบับนี้
                </p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="font-size: 12px; color: #999; text-align: center;">
                    © 2026 LifeGuardian. All rights reserved.
                </p>
            </div>
        </div>
    `;

    // Send email
    try {
        await transporter.sendMail({
            from: '"LifeGuardian Support" <lifeguardian.service@gmail.com>',
            to: email,
            subject: `รหัสยืนยันตัวตน LifeGuardian ของคุณ: ${otp}`,
            html: htmlContent
        });

        console.log(`OTP email sent successfully to ${email}`);
        return { success: true };
    } catch (error) {
        console.error('Error sending OTP email:', error);
        throw new HttpsError('internal', 'Failed to send email');
    }
});

const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const axios = require('axios');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

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


exports.sendOTPEmail = onCall({ cors: true }, async (request) => {
    const { email, otp } = request.data;

    // Validate input
    if (!email || !otp) {
        throw new HttpsError('invalid-argument', 'Email and OTP are required');
    }

    // 0. Verify if user actually exists in Auth so we don't send emails to unregistered users
    try {
        await admin.auth().getUserByEmail(email);
    } catch (error) {
        if (error.code === 'auth/user-not-found') {
            throw new HttpsError('not-found', 'user-not-found');
        }
        throw new HttpsError('internal', 'Error checking user existence');
    }

    // --- 1. Store OTP in Firestore ---
    try {
        // Store in 'otp_requests' collection, using email as ID
        // Set expiration to 10 minutes from now
        const expiresAt = Date.now() + (10 * 60 * 1000);
        await db.collection('otp_requests').doc(email).set({
            otp: otp,
            expiresAt: expiresAt,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`OTP stored for ${email}`);
    } catch (error) {
        console.error('Error storing OTP:', error);
        throw new HttpsError('internal', 'Failed to generate OTP system record');
    }

    // --- 2. Create transporter with Gmail ---
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: 'lifeguardian.service@gmail.com',
            pass: process.env.GMAIL_PASS
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

exports.resetPasswordWithOTP = onCall({ cors: true }, async (request) => {
    const { email, otp, newPassword } = request.data;

    // Validate input
    if (!email || !otp || !newPassword) {
        throw new HttpsError('invalid-argument', 'Email, OTP, and New Password are required');
    }

    try {
        // 1. Verify OTP from Firestore
        const docRef = db.collection('otp_requests').doc(email);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'ไม่พบรายการคำขอรีเซ็ตรหัสผ่าน (กรุณากดส่งรหัสใหม่)');
        }

        const data = doc.data();
        const now = Date.now();

        if (data.otp !== otp) {
            throw new HttpsError('invalid-argument', 'รหัส OTP ไม่ถูกต้อง');
        }

        if (data.expiresAt < now) {
            throw new HttpsError('deadline-exceeded', 'รหัส OTP หมดอายุแล้ว (กรุณากดส่งรหัสใหม่)');
        }

        // 2. OTP Valid! Update Password via Admin SDK
        const user = await admin.auth().getUserByEmail(email);
        await admin.auth().updateUser(user.uid, {
            password: newPassword,
        });

        // 3. Delete used OTP (One-time use)
        await docRef.delete();

        console.log(`Password reset successfully with OTP for: ${email}`);
        return { success: true, message: 'Password reset successfully' };

    } catch (error) {
        console.error('Error in resetPasswordWithOTP:', error);
        if (error instanceof HttpsError) {
            throw error;
        }
        // Handle unexpected errors
        throw new HttpsError('internal', `Reset failed: ${error.message}`);
    }
});


// LINE Messaging API Configuration (Hiding secrets for security)
const LINE_CHANNEL_ACCESS_TOKEN = process.env.LINE_CHANNEL_ACCESS_TOKEN;
const LINE_CHANNEL_SECRET = process.env.LINE_CHANNEL_SECRET;

/**
 * ส่งข้อความ LINE Push Message (plain text)
 * @param {string} lineUserId - LINE User ID ของผู้รับ
 * @param {string} text - ข้อความที่จะส่ง
 */
async function sendLinePushText(lineUserId, text) {
    try {
        await axios.post(
            'https://api.line.me/v2/bot/message/push',
            {
                to: lineUserId,
                messages: [{ type: 'text', text }],
            },
            {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
                },
            }
        );
        console.log(`LINE text sent to ${lineUserId}: ${text.substring(0, 40)}...`);
        return true;
    } catch (error) {
        console.error(`Error sending LINE text:`, error.response?.data || error.message);
        return false;
    }
}

/**
 * ส่งการแจ้งเตือนฉุกเฉินแบบ Flex Message + จำลองสถานะเจ้าหน้าที่
 * @param {string} lineUserId - LINE User ID ของเจ้าหน้าที่
 * @param {object} notiData - ข้อมูลการแจ้งเตือน {title, message, latitude, longitude, patientName, cameraId}
 */
async function sendLineEmergencyAlert(lineUserId, notiData) {
    // สร้าง Google Maps link ถ้ามีพิกัด GPS
    let locationText = 'ไม่ทราบตำแหน่ง';
    let mapUrl = '';
    if (notiData.latitude && notiData.longitude) {
        locationText = `${notiData.latitude.toFixed(6)}, ${notiData.longitude.toFixed(6)}`;
        mapUrl = `https://www.google.com/maps?q=${notiData.latitude},${notiData.longitude}`;
    }

    const timeText = new Date().toLocaleString('th-TH', { timeZone: 'Asia/Bangkok' });
    const patientName = notiData.patientName || 'ไม่ทราบชื่อ';
    const cameraId = notiData.cameraId || 'หลัก';

    // Flex Message หลัก
    const flexMessage = {
        type: 'flex',
        altText: `🚨 ตรวจพบการล้ม! ผู้ป่วย: ${patientName}`,
        contents: {
            type: 'bubble',
            size: 'mega',
            header: {
                type: 'box',
                layout: 'vertical',
                contents: [
                    {
                        type: 'text',
                        text: '🚨 แจ้งเตือนฉุกเฉิน',
                        weight: 'bold',
                        size: 'xl',
                        color: '#FFFFFF',
                    },
                    {
                        type: 'text',
                        text: notiData.title || 'ตรวจพบการล้ม!',
                        size: 'sm',
                        color: '#FFD0D0',
                        margin: 'xs',
                    },
                ],
                backgroundColor: '#DC2626',
                paddingAll: '16px',
            },
            body: {
                type: 'box',
                layout: 'vertical',
                spacing: 'sm',
                paddingAll: '16px',
                contents: [
                    {
                        type: 'box',
                        layout: 'baseline',
                        spacing: 'sm',
                        contents: [
                            { type: 'text', text: '👤 ผู้ป่วย:', size: 'sm', color: '#888888', flex: 3 },
                            { type: 'text', text: patientName, size: 'sm', color: '#111111', flex: 5, weight: 'bold', wrap: true },
                        ],
                    },
                    {
                        type: 'box',
                        layout: 'baseline',
                        spacing: 'sm',
                        contents: [
                            { type: 'text', text: '📷 กล้อง:', size: 'sm', color: '#888888', flex: 3 },
                            { type: 'text', text: cameraId, size: 'sm', color: '#111111', flex: 5, wrap: true },
                        ],
                    },
                    {
                        type: 'box',
                        layout: 'baseline',
                        spacing: 'sm',
                        contents: [
                            { type: 'text', text: '📍 ตำแหน่ง:', size: 'sm', color: '#888888', flex: 3 },
                            { type: 'text', text: locationText, size: 'sm', color: '#111111', flex: 5, wrap: true },
                        ],
                    },
                    {
                        type: 'box',
                        layout: 'baseline',
                        spacing: 'sm',
                        contents: [
                            { type: 'text', text: '🕐 เวลา:', size: 'sm', color: '#888888', flex: 3 },
                            { type: 'text', text: timeText, size: 'sm', color: '#111111', flex: 5, wrap: true },
                        ],
                    },
                ],
            },
            footer: mapUrl ? {
                type: 'box',
                layout: 'vertical',
                paddingAll: '12px',
                contents: [
                    {
                        type: 'button',
                        action: {
                            type: 'uri',
                            label: '📍 ดูตำแหน่งบนแผนที่',
                            uri: mapUrl,
                        },
                        style: 'primary',
                        color: '#0D9488',
                        height: 'sm',
                    },
                ],
            } : undefined,
        },
    };

    try {
        await axios.post(
            'https://api.line.me/v2/bot/message/push',
            { to: lineUserId, messages: [flexMessage] },
            {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
                },
            }
        );
        console.log(`✅ Emergency LINE alert sent to ${lineUserId}`);

        // จำลองสถานะเจ้าหน้าที่ตอบรับ (Rescue Status Simulation)
        const rescueUpdates = [
            { delayMs: 5000,  text: `🚑 รับทราบเหตุการณ์แล้ว กำลังส่งเจ้าหน้าที่ไปยังจุดเกิดเหตุ\n\n👤 ผู้ป่วย: ${patientName}\n📷 ที่มา: การจำลองผ่านกล้อง ${cameraId}` },
            { delayMs: 15000, text: `🚗 เจ้าหน้าที่กำลังเดินทางไปยังพิกัดที่ตรวจพบ\n📍 ${locationText}` },
            { delayMs: 30000, text: `📍 เจ้าหน้าที่ถึงที่เกิดเหตุแล้ว กำลังเข้าตรวจสอบสถานการณ์` },
            { delayMs: 45000, text: `✅ ผู้ป่วยได้รับการช่วยเหลือเรียบร้อยแล้ว\n\nเหตุการณ์: ${notiData.title || 'ตรวจพบการล้ม'}\n👤 ผู้ป่วย: ${patientName}\n🕐 เวลา: ${timeText}` },
        ];

        for (const update of rescueUpdates) {
            setTimeout(async () => {
                await sendLinePushText(lineUserId, update.text);
            }, update.delayMs);
        }

        return true;
    } catch (error) {
        console.error(`Error sending emergency LINE alert:`, error.response?.data || error.message);
        return false;
    }
}

// Secrets are handled via environment variables now

exports.onNotificationCreated = onDocumentCreated({
    document: "users/{uid}/notifications/{notiId}",
    secrets: ["LINE_CHANNEL_ACCESS_TOKEN", "LINE_CHANNEL_SECRET"]
}, async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notiData = snapshot.data();
    const patientUid = event.params.uid;

    // ส่งเฉพาะ notification ประเภท 'danger' (การล้ม) เท่านั้น
    if (notiData.type !== 'danger' && notiData.type !== 'emergency') {
        console.log(`Skipping non-emergency notification: ${notiData.type}. Full data:`, JSON.stringify(notiData));
        return;
    }

    console.log(`🚨 Emergency detected for patient ${patientUid}: ${notiData.title}`);
    console.log(`📝 Notification data:`, JSON.stringify(notiData));

    try {
        // --- [AI/Standard Logic] FCM Broadcast to Caregivers ---
        // 1. Find groups this user belongs to as the monitored person
        const groupsSnapshot = await db.collection('groups').where('ownerUid', '==', patientUid).get();
        const caregiverTokens = new Set();

        for (const groupDoc of groupsSnapshot.docs) {
            const groupId = groupDoc.id;
            const membersSnapshot = await db.collection('groups').doc(groupId).collection('members').get();

            for (const memberDoc of membersSnapshot.docs) {
                const memberUid = memberDoc.id;
                const memberData = memberDoc.data();
                if (memberData.role === 'caretaker' || memberData.role === 'owner') {
                    const caregiverDoc = await db.collection('users').doc(memberUid).get();
                    if (caregiverDoc.exists) {
                        const tokens = caregiverDoc.data().fcm_tokens || [];
                        console.log(`Adding ${tokens.length} tokens for caregiver ${memberUid}`);
                        tokens.forEach(t => caregiverTokens.add(t));
                    }
                }
            }
        }

        if (caregiverTokens.size > 0) {
            const message = {
                notification: { title: notiData.title, body: notiData.message },
                data: {
                    type: 'CRITICAL_EVENT',
                    userId: patientUid,
                    eventId: notiData.eventId || '',
                    latitude: (notiData.latitude || '').toString(),
                    longitude: (notiData.longitude || '').toString(),
                    imageUrl: notiData.imageUrl || '',
                    confidence: (notiData.confidence || '').toString(),
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                },
                tokens: Array.from(caregiverTokens),
            };
            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`${response.successCount} FCM messages sent`);
        } else {
            console.log("No caregivers found for FCM.");
        }

        // --- [Line Noti Logic] Priority: Emergency Alerts ---
        // ดึง LINE User ID ของเจ้าหน้าที่จาก Firestore config
        const configDoc = await db.collection('app_config').doc('line_settings').get();
        let emergencyLineId = null;

        if (configDoc.exists) {
            emergencyLineId = configDoc.data().emergencyContactLineId;
            console.log(`Found config doc. Line ID: ${emergencyLineId}`);
        } else {
            console.log(`Config doc app_config/line_settings not found`);
        }

        if (!emergencyLineId) {
            console.log("No emergency LINE contact configured. Set it in Firestore: app_config/line_settings.emergencyContactLineId");
            return;
        }

        // ดึงชื่อคนไข้จาก Firestore
        let patientName = 'ไม่ทราบชื่อ';
        try {
            const patientDoc = await db.collection('users').doc(patientUid).get();
            if (patientDoc.exists) {
                patientName = patientDoc.data().name || patientDoc.data().displayName || 'ไม่ทราบชื่อ';
            }
        } catch (e) {
            console.error("Error fetching patient name:", e);
        }

        // รวมข้อมูลทั้งหมดเพื่อส่งไปใน Flex Message
        const enrichedNotiData = {
            ...notiData,
            patientName,
            cameraId: notiData.cameraId || 'ไม่ทราบกล้อง',
            imageUrl: notiData.imageUrl || notiData.remoteImageUrl || '',
        };

        console.log(`Attempting to send LINE alert to: ${emergencyLineId}`);

        const success = await sendLineEmergencyAlert(emergencyLineId, enrichedNotiData);

        if (success) {
            console.log(`✅ Emergency LINE alert sent successfully`);
        } else {
            console.error(`❌ Failed to send LINE alert to emergency contact`);
        }
    } catch (error) {
        console.error("Error in onNotificationCreated processing:", error);
    }
});

// ===== LINE Webhook Handler =====
exports.lineWebhook = onRequest({ 
    cors: true,
    secrets: ["LINE_CHANNEL_ACCESS_TOKEN", "LINE_CHANNEL_SECRET"]
}, async (req, res) => {
    const signature = req.headers['x-line-signature'];
    const body = JSON.stringify(req.body);
    const hash = crypto.createHmac('sha256', LINE_CHANNEL_SECRET).update(body).digest('base64');

    if (signature !== hash) {
        console.error('LINE webhook signature mismatch');
        return res.status(403).send('Forbidden');
    }

    const events = req.body.events || [];
    for (const event of events) {
        const lineUserId = event.source?.userId;
        if (!lineUserId) continue;

        console.log(`LINE event: ${event.type} from ${lineUserId}`);

        if (event.type === 'follow') {
            // เมื่อมีคนเพิ่ม Bot เป็นเพื่อน — แสดงข้อความต้อนรับเจ้าหน้าที่
            await axios.post(
                'https://api.line.me/v2/bot/message/reply',
                {
                    replyToken: event.replyToken,
                    messages: [
                        {
                            type: 'text',
                            text: `🚨 LifeGuardian — ระบบแจ้งเหตุฉุกเฉิน\n\nคุณได้รับการเชื่อมต่อกับระบบตรวจจับการล้มอัตโนมัติแล้ว\n\n✅ เมื่อระบบตรวจพบการล้ม Bot นี้จะแจ้งเตือนคุณทันที พร้อมข้อมูล:\n• ชื่อผู้ป่วย\n• กล้องที่ตรวจพบ\n• ตำแหน่ง GPS\n• เวลาที่เกิดเหตุ`,
                        },
                    ],
                },
                {
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
                    },
                }
            );
        } else if (event.type === 'message' && event.message?.type === 'text') {
            // เมื่อมีคนส่งข้อความมา — แจ้งว่า Bot ใช้สำหรับรับแจ้งเหตุเท่านั้น
            await axios.post(
                'https://api.line.me/v2/bot/message/reply',
                {
                    replyToken: event.replyToken,
                    messages: [
                        {
                            type: 'text',
                            text: `🤖 LifeGuardian Bot\n\nBot นี้ใช้สำหรับรับแจ้งเหตุฉุกเฉินอัตโนมัติจากระบบตรวจจับการล้ม\n\n⚠️ ไม่สามารถตอบกลับข้อความได้ กรุณารอรับการแจ้งเตือนเมื่อเกิดเหตุ`,
                        },
                    ],
                },
                {
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${LINE_CHANNEL_ACCESS_TOKEN}`,
                    },
                }
            );
        }
    }
    res.status(200).send('OK');
});

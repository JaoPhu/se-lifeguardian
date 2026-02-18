# LifeGuardian

LifeGuardian is a mobile-native application for AI-powered office syndrome monitoring and event detection. It utilizes advanced computer vision via Flutter and Google ML Kit to analyze user posture and detect critical safety events such as falling, long-term sitting, or improper ergonomic positioning to ensure workplace wellness.

## 🛠️ Tech Stack & Languages

This project is built using a cross-platform mobile approach (Flutter), focusing on high-performance AI integration and a premium native user experience.

### Languages Used
- **Dart**: Used for 100% of the application logic, state management, and UI development to ensure high performance and smooth animations.

### Core Technologies
- **Framework**: [Flutter](https://flutter.dev/) (Channel stable, ^3.4.3)
- **State Management**: [Riverpod](https://riverpod.dev/) (flutter_riverpod)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **AI Engine**: [Google ML Kit Pose Detection](https://developers.google.com/ml-kit/vision/pose-detection) (**Powered by MediaPipe** for on-device real-time processing)
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)
- **Package Manager**: [pub](https://pub.dev/)

---

## 🚀 Getting Started

Follow these steps to set up the project locally for development.

### 1. Clone the Repository
```bash
git clone https://github.com/JaoPhu/se-lifeguardian.git
cd lifeguardian
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Development App
```bash
flutter run
```

---

## 🏗️ Building for Production
```bash
flutter build apk # For Android
flutter build ios # For iOS
```

### 🍎 iOS Setup (Mac Only)
If you are running on macOS and want to build for iOS, you must install dependencies for CocoaPods:

```bash
# 1. Enter iOS directory
cd ios

# 2. Install Pods
pod install

# 3. Return to root
cd ..
```

## ❓ Troubleshooting

### iOS: "Framework Pods_Runner not found"
If you encounter this error, it means the CocoaPods dependencies are not linked correctly. Run the following:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
```
Then try running the app again.

---

## 🛡️ Firebase & Admin SDK Setup

For security reasons, sensitive configuration files are excluded from version control (via `.gitignore`). If you are a new collaborator, you must perform the following:

### 1. Project Configuration
- Place your `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) in their respective platform directories.

### 2. Admin SDK (Backend/Scripts)
If you need to run local administrative scripts or modify Cloud Functions:
- Generate a new **Private Key** from the [Firebase Console](https://console.firebase.google.com/) (Project Settings > Service Accounts).
- Rename the file to `serviceAccountKey.json`.
- Place it in the `functions/` directory.
- **NEVER** commit this file. It is already ignored by Git to prevent security leaks.

### ⚠️ Database Support & Self-Hosting
- **Current Database**: The default Firebase project connected to this repository is intended for demonstration purposes. **Access to this database will be maintained for a limited time and will eventually be closed.**
- **Taking it Further**: If you plan to fork this project or use it long-term, we strongly recommend setting up your own Firebase environment:
    1. Create a new project on the [Firebase Console](https://console.firebase.google.com/).
    2. Enable **Firestore**, **Authentication**, **Storage**, and **Functions** (Blaze Plan).
    3. Update the `google-services.json` and `GoogleService-Info.plist` with your new project's credentials.
    4. **Email Service (OTP)**: The default registration uses a hardcoded Gmail transporter in Cloud Functions. If you set up your own project, you **must** update the `transporter` config in `functions/index.js` with your own SMTP/API credentials (e.g., SendGrid, Mailgun, or another Gmail app password).
    5. Deploy the existing rules and functions using `firebase deploy`.

---

## 📂 Project Structure
```
lib/
├── src/
│   ├── features/      # Feature-first architecture
│   │   ├── authentication/ # Unified Onboarding, Login, Register
│   │   ├── dashboard/      # Multi-camera overview & Live monitoring
│   │   ├── statistics/     # Modern Analytics & Weekly Charts
│   │   ├── group/          # Consolidated Group Management
│   │   ├── profile/        # User Profile & Medical Info
│   │   ├── pose_detection/ # AI Engine (Kalman Filter & Temporal Analysis)
│   │   └── notification/   # Consolidated Smart Notifications
│   ├── common/        # App Theme & Constants
│   ├── common_widgets/# Shared UI components
│   ├── routing/       # App routing (GoRouter) & Scaffold with Navbar
│   └── main.dart      # Entry point
assets/
├── icon/              # App branding & Splash assets
└── images/            # UI background and illustration assets
```

## 💡 Key Features & Recent Improvements
- **Unified Onboarding Flow**: Streamlined registration process that guides all new users (Email & Social) to a mandatory information-gathering step before accessing the dashboard.
- **Consolidated Architecture**: Streamlined project by removing redundant folders and standardizing on modern implementations.
- **CI/CD Ready**: Zero analysis issues, ensuring reliable builds on every commit.
- **Secure Password Reset (Backend)**: Custom-built 2nd Gen Firebase Cloud Functions for secure server-side password updates via Admin SDK.
- **Stale Session Fix**: Automatic Google/Apple sign-out during account deletion to prevent "Loading Loop" issues for returning users.

---

## 🇹🇭 สำหรับนักพัฒนา (Thai Summary)

**LifeGuardian คืออะไร?**
โปรเจกต์นี้เป็นแอปพลิเคชันระบบตรวจจับท่าทางและอาการออฟฟิศซินโดรมด้วย AI (On-device) พัฒนาด้วย Flutter โดยเน้นที่ความรวดเร็วในการประมวลผลและความสวยงามของ UI ระดับ Premium

**การตั้งค่าสำคัญสำหรับผู้ที่จะทำต่อ:**
1.  **ไฟล์ความลับ (Secrets)**: ไฟล์ `serviceAccountKey.json` และตัวแปรสภาพแวดล้อมต่างๆ ถูกซ่อนไว้เพื่อความปลอดภัย หากต้องการใช้งาน Admin SDK ในเครื่องตัวเอง ให้เจนกุญแจใหม่จาก Firebase Console และวางไว้ที่โฟลเดอร์ `functions/` ครับ
2.  **นโยบายฐานข้อมูล (Database Policy)**: ฐานข้อมูล Firebase ที่เชื่อมต่ออยู่ปัจจุบันมีไว้เพื่อการทดสอบเท่านั้น **จะมีการเปิดให้ใช้งานได้ชั่วระยะเวลาหนึ่งและจะถูกปิดลงในอนาคต** เพื่อความยั่งยืน แนะนำให้ผู้ที่จะพัฒนาต่อทำการตั้งค่า Firebase Project ของตนเองและอัปเดตไฟล์คอนฟิก (`google-services.json`, `GoogleService-Info.plist`) ครับ
3.  **ระบบอีเมล (OTP)**: ฟีเจอร์การส่งรหัส OTP ผ่านอีเมลทำงานผ่าน Cloud Functions หากคุณแยกตัวฐานข้อมูลออกไป คุณจำเป็นต้องตั้งค่า Email Transporter ของตัวเองใน `functions/index.js` (เช่น ใช้ SendGrid หรือ App Password ของ Gmail ตนเอง) เพราะระบบปัจจุบันจะถูกปิดตัวลงพร้อมกับฐานข้อมูลครับ
4.  **Unified Onboarding**: ระบบจะบังคับให้ผู้ใช้ใหม่ทุกคนเตรียมโปรไฟล์ให้เสร็จในหน้า **"Information"** ก่อนเสมอ หากมีการแก้ไขระบบ Routing ใน `AppRouter.dart` โปรดระวังจุดนี้ด้วยครับ
5.  **การแก้ไข Region**: ปัจจุบัน Cloud Functions รันอยู่ที่ `us-central1` หากมีการย้าย Server ต้องอัปเดตทั้งในแอป (AuthRepository) และในไฟล์ `index.js` ฝั่ง Functions ให้ตรงกันครับ

> **สถานะปัจจุบัน**: พัฒนาเสร็จสมบูรณ์ทั้งระบบ **Secure Auth**, **Unified Onboarding**, **AI Stability Engine**, และผ่านการ **Clean-up** ให้พร้อมสำหรับการ Deploy ระดับ Production แล้วครับ
---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

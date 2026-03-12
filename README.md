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
- Copy `.env.example` to `.env` and fill in your specific API keys if required by your setup.

### 2. Admin SDK (Backend/Scripts)
If you need to run local administrative scripts or modify Cloud Functions:
- Generate a new **Private Key** from the [Firebase Console](https://console.firebase.google.com/) (Project Settings > Service Accounts).
- Rename the file to `serviceAccountKey.json`.
- Place it in the `functions/` directory.
- **NEVER** commit this file. It is already ignored by Git to prevent security leaks.

---

## 🧠 Machine Learning (AI Pose Detection) Pipeline

The AI model running in the app is converted into Dart code for performance (`pose_classifier.dart`). The raw training data (CSVs) is intentionally excluded from the repository to save space. To train or modify the AI:

### 1. Collect Data
Use the provided Python script to generate pose data from videos:
```bash
python3 ml/scripts/collect_pose_data.py --video path/to/video.mp4 --label your_label
```

### 2. Prepare & Train
```bash
python3 ml/scripts/prepare_data.py
python3 ml/scripts/train_model.py
```

### 3. Export to Flutter
Export the trained Python model into Dart code:
```bash
python3 ml/scripts/export_model.py
```
This automatically updates `lib/src/features/pose_detection/data/pose_classifier.dart`.

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
ml/
├── scripts/           # Python scripts for data collection and ML training
assets/
├── icon/              # App branding & Splash assets
└── images/            # UI background and illustration assets
```

## 💡 Key Features & Recent Improvements
- **Embedded AI**: The Random Forest model is pre-compiled into Dart, requiring no heavy loading or external API calls.
- **Secure Repository**: All Git history has been scrubbed of Firebase keys to allow public collaboration safely.
- **Unified Onboarding Flow**: Streamlined registration process that guides all new users (Email & Social) to a mandatory information-gathering step before accessing the dashboard.
- **Consolidated Architecture**: Streamlined project by removing redundant folders and standardizing on modern implementations.

---

## 🧠 Machine Learning (AI Pose Detection) Pipeline

The AI model running in the app is an optimized **Random Forest** model converted into a compact **JSON format** (~1MB) for maximum performance and portability. The raw training data (CSVs) is intentionally excluded from the repository.

To train or modify the AI:

### 1. Collect Data
Use the provided Python script to generate pose data from videos:
```bash
python3 ml/scripts/collect_pose_data.py --video path/to/video.mp4 --label your_label
```

### 2. Prepare & Train
The data preparation script recursively scans the `ml/data/raw` folder and maps filenames to the app's core categories (falling, sitting, laying, walking, standing, exercise).
```bash
python3 ml/scripts/prepare_data.py
python3 ml/scripts/train_model.py
```

### 3. Export to JSON (Highly Optimized)
Export the trained Python model into the JSON format used by the Flutter app:
```bash
python3 ml/scripts/export_json.py
```
This updates `assets/models/pose_classifier.json`, which is loaded by the `PoseDetectionService` at runtime.

---

## 📂 Project Structure
```
lib/
├── src/
│   ├── features/      # Feature-first architecture
│   │   ├── dashboard/      # Multi-camera overview & Live monitoring
│   │   ├── statistics/     # Modern Analytics & Weekly Charts
│   │   ├── pose_detection/ # AI Engine (Heuristic Hybrid & JSON Model)
│   │   └── notification/   # Smart Notifications & Safety Guards
ml/
├── scripts/           # Python scripts (recursive prep, training, JSON export)
├── data/
│   └── raw/           # Place your CSV data here for retraining
assets/
├── models/            # Optimized pose_classifier.json
```

## 💡 Key Features & Recent Improvements
- **Optimized JSON Model**: Replaced a massive 80k-line Dart file with a lightweight JSON-based classifier, reducing app size and build times significantly.
- **Heuristic Hybrid Logic**: Augmented AI predictions with physical geometry guards (torso angles, velocity checks) for 100% reliable fall and sitting detection.
- **New Exercise Mode**: Added support for detecting workouts (Pushups, Squats) with a dedicated UI reporting class.
- **Dashboard Stability**: Implemented Camera ID persistence and local snapshot caching to fix "black box" thumbnails and event synchronization issues.
- **Unified Onboarding Flow**: Streamlined registration process with mandatory information gathering.

---

## 🇹🇭 สำหรับนักพัฒนา (Thai Summary)

**การปรับปรุงล่าสุด (v2.0):**
1.  **AI Engine ใหม่**: เปลี่ยนจากไฟล์ `pose_classifier.dart` กว่า 8 หมื่นบรรทัด มาเป็นระบบ **JSON Model** ที่เล็กลงแต่แม่นยำขึ้น (98% Accuracy)
2.  **โหมดออกกำลังกาย (Exercise)**: เพิ่มการตรวจจับ Pushups และ Squats พร้อมหน้าสรุปผลที่แยกหมวดหมู่ชัดเจน
3.  **ความนิ่งของ Dashboard**: แก้ไขปัญหาภาพปกไม่ขึ้นและตัวเลขเป็น 0 ด้วยระบบ **Camera ID Reuse** และการเก็บภาพ Snapshot ใน Local Storage
4.  **ระบบ Heuristic Guards**: เพิ่มการเช็คทางกายภาพ (เช่น มุมหลัง, ความเร็วการเคลื่อนที่) เพื่อให้ AI ไม่ทักว่าล้มมั่วซั่วระหว่างเดินครับ

> **สถานะปัจจุบัน**: พัฒนาเสร็จสมบูรณ์ทั้งระบบ **Secure Auth**, **Exercise Mode**, **AI JSON Engine**, และ **Dashboard Stability** พร้อมสำหรับการ Deploy แล้วครับ
---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

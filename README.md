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

## 📂 Project Structure
```
lib/
├── src/
│   ├── features/      # Feature-first architecture (Auth, Statistics, Dashboard, etc.)
│   │   ├── auth/      # Login, Register, Profile Management
│   │   ├── dashboard/ # Multi-camera overview & Live monitoring
│   │   ├── statistics/# Analytics, Circular Gauges & Weekly Charts
│   │   └── ...
│   ├── common_widgets/# Shared UI components
│   ├── routing/       # App routing (GoRouter) & Scaffold with Navbar
│   └── main.dart      # Entry point
assets/
├── icon/              # App branding & Splash assets
└── images/            # UI background and illustration assets
```

## 💡 Key Features Implemented
- **Multi-Camera Management**: Ability to register and manage multiple cameras with custom display names.
- **Camera-Specific Data Segregation**: Every event is tagged with a unique `cameraId`, allowing for independent history logs and targeted data cleanup per camera.
- **Advanced Posture Classification**: Granular detection for **Sitting** (`นั่งพัก`) and **Slouching/Unconscious** (`สลบ / ซบ`) states, alongside Fall, Laying, and Walking.
- **Smart Date-Range Display**: Dashboard cards automatically calculate and display the event date range (`YYYY/MM/DD`) for each specific camera.
- **Optimized 16:9 Analysis Layout**: Refined video analysis screen with a centered 16:9 aspect ratio and automated black-bar padding for consistent skeletal overlay alignment.
- **Clean-State Data Management**: Integrated confirmation-guarded "Clear History" deletion for local logs and cached snapshots.
- **On-Device AI Pose Detection**: Real-time skeletal tracking using Google ML Kit (v2025) for privacy and zero-latency performance.
- **Precision Activity Ring**: High-fidelity circular gauge for monitoring daily health goals.
- **Weekly Analytics**: Clean, minimal bar charts for long-term activity tracking.
- **Premium Navigation**: Custom semi-floating bottom navigation bar mirroring high-end mobile designs.
- **Global Theme Support**: Full support for system-aware dark and light modes.

---

## 🇹🇭 สำหรับนักพัฒนา (Thai Summary)

**LifeGuardian คืออะไร?**
โปรเจกต์นี้เป็นแอปพลิเคชันระบบตรวจจับท่าทางและอาการออฟฟิศซินโดรมด้วย AI (On-device) พัฒนาด้วย Flutter โดยเน้นที่ความรวดเร็วในการประมวลผลและความสวยงามของ UI ระดับ Premium

**ภาษาและเทคโนโลยี:**
*   **Dart (Flutter)**: ใช้เป็นภาษาหลักในการพัฒนาแบบ Cross-platform
*   **Google ML Kit**: ใช้สำหรับตรวจจับจุดบนร่างกาย (Pose Detection) แบบ Real-time บนตัวเครื่อง (ไม่ต้องผ่าน Cloud)
*   **Riverpod**: ใช้สำหรับการจัดการ State ภายในแอปอย่างมีประสิทธิภาพ

**วิธีเริ่มโปรเจกต์:**
1.  `flutter pub get`
2.  `flutter run`

> **สถานะปัจจุบัน**: พัฒนาเสร็จสมบูรณ์ทั้งระบบ **AI Stability Engine**, **Multi-Camera Support**, และระบบ **Smart History Cleanup** (ล้างข้อมูลแยกตามรายกล้อง) พร้อมการประมวลผลท่าทางละเอียดระดับ Sitting/Slouching และดีไซน์ระดับ Premium Teal

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

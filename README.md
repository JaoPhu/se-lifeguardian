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
- **AI Stability Engine**: High-speed pre-analysis and camera motion compensation for robust tracking in handheld or dynamic environments.
- **Multi-Person ID Persistence**: Intelligent tracking that maintains individual IDs for multiple subjects across occlusion and rapid movement.
- **On-Device AI Pose Detection**: Real-time skeletal tracking using Google ML Kit (v2025) for privacy and zero-latency performance.
- **Precision Activity Ring**: High-fidelity circular gauge for monitoring daily health goals.
- **Weekly Analytics**: Clean, minimal bar charts for long-term activity tracking.
- **Multi-Camera Dashboard**: Interactive management of multiple monitoring sources with snapshot event logging.
- **Premium Navigation**: Custom semi-floating bottom navigation bar mirroring high-end mobile designs.
- **Global Theme Support**: Full support for system-aware dark and light modes.

---

## 🇹🇭 สำหรับนักพัฒนา (Thai Summary)

**LifeGuardian คืออะไร?**
โปรเจกต์นี้เป็นแอปพลิเคชันระบบตรวจจับท่าทางและอาการออฟฟิศซินโดรมด้วย AI (On-device) พัฒนาด้วย Flutter โดยเน้นที่ความรวดเร็วในการประมวลผลและความสวยงามของ UI

**ภาษาและเทคโนโลยี:**
*   **Dart (Flutter)**: ใช้เป็นภาษาหลักในการพัฒนาแบบ Cross-platform
*   **Google ML Kit**: ใช้สำหรับตรวจจับจุดบนร่างกาย (Pose Detection) แบบ Real-time บนตัวเครื่อง (ไม่ต้องผ่าน Cloud)
*   **Riverpod**: ใช้สำหรับการจัดการ State ภายในแอปอย่างมีประสิทธิภาพ

**วิธีเริ่มโปรเจกต์:**
1.  `flutter pub get`
2.  `flutter run`

> **สถานะปัจจุบัน**: พัฒนาส่วน AI Stability Engine และระบบ Pre-analysis เสร็จสมบูรณ์ พร้อมรองรับการตรวจจับแบบหลายคน (Multi-person) อย่างแม่นยำแม้ขณะกล้องสั่นหรือวัตถุขยับเร็ว พร้อมระบบรายงานผลแบบ Snapshot รายเหตุการณ์

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

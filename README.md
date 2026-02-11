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
│   ├── features/      # Feature-first architecture
│   │   ├── authentication/ # Login, Register, Forget Password
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
- **Consolidated Architecture**: Streamlined project by removing redundant folders (`groups`, `NotificationPage`) and standardizing on modern implementations.
- **CI/CD Ready**: Fixed all 22+ analysis issues including `withOpacity` deprecations and missing `const` constructors. Core passes `flutter analyze` with zero issues.
- **Premium Shield UI**: Integrated a custom high-profile "Shield with Plus" button in the center navigation for quick access to safety features.
- **Modern Statistics Engine**: Replaced legacy statistics with a high-performance `StatisticsScreen` featuring real-time activity rings and interactive weekly charts.
- **Multi-Camera Management**: Ability to register and manage multiple cameras with custom display names.
- **Advanced Posture Classification**: Granular detection for **Sitting** and **Slouching** states, alongside Fall, Laying, and Walking.
- **Temporal Analysis Engine**: Enhanced AI stability using Kalman Filters and temporal buffering for more accurate event logging.
- **Smart Notification System**: A centralized notification hub with categorize alerts (Success, Warning, Danger).
- **Global Theme Support**: Full support for system-aware dark and light modes using a custom `ThemeProvider`.

---

## 🇹🇭 สำหรับนักพัฒนา (Thai Summary)

**LifeGuardian คืออะไร?**
โปรเจกต์นี้เป็นแอปพลิเคชันระบบตรวจจับท่าทางและอาการออฟฟิศซินโดรมด้วย AI (On-device) พัฒนาด้วย Flutter โดยเน้นที่ความรวดเร็วในการประมวลผลและความสวยงามของ UI ระดับ Premium

**การปรับปรุงล่าสุด:**
*   **Code Consolidation**: ยุบรวม Folder ที่ซ้ำซ้อนและลบไฟล์ที่ไม่ได้ใช้งานออก เพื่อโครงสร้างโค้ดที่สะอาดและดูแลง่าย
*   **CI Improvement**: แก้ไขปัญหา Linting/Analysis ทั้งหมด (22+ จุด) เพื่อให้สามารถรัน CI/CD บน GitHub ได้อย่างไร้รอยต่อ
*   **UI Redesign**: อัปเกรดหน้าสถิติและระบบนำทางให้เป็นรูปแบบ Modern พร้อมปุ่ม Shield UI แบบพิเศษ

> **สถานะปัจจุบัน**: พัฒนาเสร็จสมบูรณ์ทั้งระบบ **AI Stability Engine**, **Multi-Camera Support**, และผ่านการ **Cleanup** โครงสร้างโปรเจกต์ทั้งหมดแล้ว พร้อมสำหรับการต่อยอดในระดับ Production
---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

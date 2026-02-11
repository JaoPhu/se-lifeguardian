# Contributing to LifeGuardian

Welcome to the LifeGuardian team! Here's how to get started and keep our code clean.

## 🛠 Setup

1.  **Flutter Version**: Ensure you are using Flutter 3.19.x or later.
2.  **Dependencies**: Run `flutter pub get`.
3.  **iOS Setup** (Mac Only):
    *   Navigate to the iOS folder: `cd ios`
    *   Install Pods: `pod install`
    *   *Troubleshooting*: If you see `PhaseScriptExecution` errors, run `flutter clean` then `flutter pub get` again.

## 🏗 Architecture

We use a feature-first architecture:
- `lib/src/features/`: Contains all feature modules (Pose Detection, Dashboard, etc.).
- `lib/src/shared/`: Shared UI components and utilities.

State Management: **Riverpod**.

## 🧪 Testing & Linting

Before pushing code:
1.  Run `flutter analyze` to check for lint errors.
2.  Fix any warnings.
3.  Format your code: `dart format .`

## 🚀 Deployment

The CI/CD pipeline (`.github/workflows/flutter_build.yml`) automatically builds the Android APK on every push to `main`.

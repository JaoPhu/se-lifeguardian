# Contributing to LifeGuardian

Welcome to the LifeGuardian team! Here's how to get started and keep our code clean.

## 🛠 Setup

1.  **Flutter Version**: Ensure you are using Flutter 3.24.x or later.
2.  **Dependencies**: Run `flutter pub get`.
3.  **Backend Setup**:
    *   Install Firebase CLI: `npm install -g firebase-tools`
    *   Functions Setup: `cd functions && npm install`
    *   Note: Deployment requires a **Blaze (Pay-as-you-go)** plan for 2nd Gen Cloud Functions.
4.  **iOS Setup** (Mac Only):
    *   Navigate to the iOS folder: `cd ios`
    *   Install Pods: `pod install`
    *   **Important**: If you have Homebrew GCC installed, you may face toolchain conflicts. Our `ios/Podfile` contains a workaround to sanitize build paths.

## 🏗 Architecture

We follow a **Feature-First Architecture**:
- `lib/src/features/[feature_name]/`:
  - `data/`: Repositories and data sources.
  - `domain/`: Models and business logic.
  - `presentation/`: UI components and controllers.
- `lib/src/common/`: App-wide theme, constants, and utilities.
- `lib/src/routing/`: App navigation logic.

State Management: **Riverpod** (with version 2.x patterns).

## 🌍 Localization & Standards

- **Language**: The app primarily targets Thai users. New features should include Thai translations for dialogs, labels, and emails.
- **Security**: Never hardcode credentials. Use environment variables (future plan) or secure storage.

## 🧪 Testing & Linting

Before pushing code:
1.  Run `flutter analyze` - We maintain a clean codebase with zero warnings.
2.  Run `dart format .`
3.  Ensure `walkthrough.md` is updated if you add new features.

## 🚀 Deployment

- **GitHub Actions**: Automated APK builds are triggered on every push to `main`.
- **Firebase Functions**: Deploy via `firebase deploy --only functions`.

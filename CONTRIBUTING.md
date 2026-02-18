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
    *   **Toolchain Conflicts**: If you have Homebrew GCC installed, you may face toolchain conflicts (e.g., `'cstddef' not found` or declaration conflicts).
        *   **Fix**: Ensure `CPATH` and `LIBRARY_PATH` are NOT set in your shell profile (`.zshrc`, `.bash_profile`).
        *   **Workaround**: Our `ios/Podfile` contains a `post_init` hook that sanitizes search paths and isolates `leveldb-library` from Homebrew headers.
4.  **Database Setup (For Forking/Self-hosting)**:
    Since the current database will be closed in the future, you must set up your own Firebase project for sustained development:
    *   Create a project on [Firebase Console](https://console.firebase.google.com/).
    *   **Firestore**: Enable and use the rules in `firestore.rules`.
    *   **Authentication**: Enable Email/Password, Google, and Apple sign-in.
    *   **Storage**: Enable and use the rules in `storage.rules`.
    *   **Functions**: 
        *   `cd functions && npm install`.
        *   **Email Setup**: Update `functions/index.js`. Locate the `nodemailer.createTransport` section and provide your own SMTP credentials or integrate a service like SendGrid. The current Gmail account is for demo purposes and will be retired.
        *   Deploy via `firebase deploy --only functions`.
    *   **Config Files**: Update `lib/src/features/authentication/data/auth_repository.dart` if you change regions, and replace `google-services.json` / `GoogleService-Info.plist`.

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

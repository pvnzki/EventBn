# Development Setup Guide

## Prerequisites

Before starting development, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (>=3.0.0)

   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Dart SDK** (comes with Flutter)

3. **Android Studio** or **VS Code**

   - Android Studio: https://developer.android.com/studio
   - VS Code with Flutter extension: https://code.visualstudio.com/

4. **Git**
   - For version control and repository management

### Mobile Development Setup

#### Android Development

1. Install Android Studio
2. Install Android SDK (API level 31 or higher)
3. Set up Android emulator or connect physical device
4. Enable Developer Options and USB Debugging on physical device

#### iOS Development (macOS only)

1. Install Xcode from Mac App Store
2. Install Xcode Command Line Tools: `xcode-select --install`
3. Set up iOS Simulator or connect physical device

## Project Setup

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd mobile-app

# Install dependencies
flutter pub get

# Generate code for models
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 2. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your configuration
# Required variables:
# - BASE_URL: Your backend API URL
# - STRIPE_PUBLISHABLE_KEY: Your Stripe publishable key
# - STRIPE_SECRET_KEY: Your Stripe secret key (backend use)
```

### 3. IDE Configuration

#### VS Code Setup

Install these extensions:

- Flutter
- Dart
- Flutter Tree
- Bracket Pair Colorizer
- GitLens

#### Android Studio Setup

Install these plugins:

- Flutter
- Dart

### 4. Device Setup

#### Android Emulator

```bash
# List available devices
flutter devices

# Create new emulator (if needed)
# Use Android Studio AVD Manager or command line:
avdmanager create avd -n flutter_emulator -k "system-images;android-31;google_apis;x86_64"
```

#### iOS Simulator (macOS)

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 14"
```

## Development Workflow

### 1. Running the App

```bash
# Run on connected device/emulator
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device-id>
```

### 2. Code Generation

```bash
# Generate code for models (JSON serialization)
flutter packages pub run build_runner build

# Watch for changes and auto-generate
flutter packages pub run build_runner watch

# Clean and regenerate
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 3. Testing

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### 4. Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Fix auto-fixable issues
dart fix --apply
```

## Development Best Practices

### 1. Code Organization

- Follow the established folder structure
- Keep features modular and independent
- Use meaningful file and variable names
- Add comments for complex logic

### 2. State Management

- Use Provider for state management
- Keep providers focused on single responsibility
- Handle loading and error states properly
- Avoid unnecessary widget rebuilds

### 3. API Integration

- Use the service layer for all API calls
- Handle network errors gracefully
- Implement retry mechanisms where appropriate
- Use proper HTTP status code handling

### 4. UI/UX Guidelines

- Follow Material Design principles
- Ensure responsive design for different screen sizes
- Implement proper loading states
- Provide user feedback for all actions

### 5. Error Handling

- Implement global error handling
- Provide user-friendly error messages
- Log errors for debugging
- Handle edge cases gracefully

## Debugging

### 1. Debug Tools

```bash
# Flutter Inspector (widget tree)
flutter inspector

# Debug with DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### 2. Common Issues

#### Build Issues

```bash
# Clean build
flutter clean
flutter pub get

# Clear Gradle cache (Android)
cd android && ./gradlew clean

# Clear Xcode build (iOS)
cd ios && rm -rf build/
```

#### Hot Reload Issues

```bash
# Full restart
flutter run --hot

# If hot reload stops working
# Press 'R' in terminal or restart the app
```

## Deployment Preparation

### 1. Android Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### 2. iOS Release

```bash
# Build for iOS
flutter build ios --release
```

### 3. Environment-Specific Builds

```bash
# Development build
flutter build apk --debug --flavor dev

# Staging build
flutter build apk --release --flavor staging

# Production build
flutter build apk --release --flavor prod
```

## Troubleshooting

### Common Flutter Issues

1. **Doctor Issues**

```bash
flutter doctor
# Fix any issues reported
```

2. **Dependency Conflicts**

```bash
flutter pub deps
flutter pub upgrade
```

3. **Platform Issues**

```bash
# Android
flutter clean
cd android && ./gradlew clean

# iOS
flutter clean
cd ios && rm -rf Pods/ Podfile.lock
pod install
```

### Performance Tips

1. **Optimize Build Size**

- Use `flutter build apk --split-per-abi`
- Remove unused dependencies
- Optimize images and assets

2. **Improve Performance**

- Use const constructors where possible
- Avoid rebuilding widgets unnecessarily
- Use ListView.builder for large lists
- Profile app performance with DevTools

## Additional Resources

### Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Provider Package](https://pub.dev/packages/provider)
- [GoRouter](https://pub.dev/packages/go_router)

### Community

- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [Flutter Discord](https://discord.gg/flutter)

---

Happy coding! 🚀

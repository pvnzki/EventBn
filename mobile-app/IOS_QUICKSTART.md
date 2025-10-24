# Quick Start Guide - iOS Development for EventBn

## 🚀 One-Time Setup (macOS Required)

### 1. Prerequisites Check
```bash
# Check Flutter installation
flutter doctor -v

# Ensure you see:
# ✓ Flutter
# ✓ Xcode
# ✓ CocoaPods
```

### 2. Install iOS Dependencies
```bash
cd ios
pod install
cd ..
```

**Expected output:**
```
Analyzing dependencies
Downloading dependencies
Installing dependencies
Generating Pods project
Pod installation complete!
```

### 3. Verify Setup
```bash
# List available simulators
flutter emulators

# Should show iOS simulators like:
# • iPhone 15 Pro
# • iPad Pro (12.9-inch)
```

## 🏃‍♂️ Running the App

### On iOS Simulator (Fastest)
```bash
# Run on any available simulator
flutter run

# Or specify simulator
flutter run -d iphone
```

### On Physical iPhone/iPad
```bash
# 1. Connect device via USB
# 2. Trust computer on device
# 3. List devices
flutter devices

# 4. Run on device
flutter run -d <your-device-id>
```

## 🔧 Common Development Tasks

### Hot Reload
While app is running:
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Clean Build
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Update Dependencies
```bash
flutter pub get
cd ios && pod install && cd ..
```

## 📱 Testing Both Platforms

### Quick Test Script
```bash
# Test Android
flutter run -d android

# Test iOS
flutter run -d iphone

# Or run both (in different terminals)
```

### Automated Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

## 🐛 Troubleshooting

### Issue: "No iOS devices found"
**Solution:**
```bash
# Open Xcode
open -a Xcode

# Xcode → Preferences → Components
# Download iOS Simulator
```

### Issue: "CocoaPods not found"
**Solution:**
```bash
sudo gem install cocoapods
pod setup
```

### Issue: "Certificate error"
**Solution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Select your team or choose "Automatically manage signing"

### Issue: "Build failed"
**Solution:**
```bash
# Clean everything
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
flutter run
```

### Issue: "Plugin not found"
**Solution:**
```bash
flutter pub get
cd ios
pod install
pod update
cd ..
```

## 📋 Pre-Release Checklist

### Android
- [ ] Test on emulator
- [ ] Test on physical device
- [ ] Check all features work
- [ ] Verify permissions
- [ ] Test deep linking

### iOS
- [ ] Test on simulator
- [ ] Test on physical device (if available)
- [ ] Check all features work
- [ ] Verify permissions
- [ ] Test deep linking

### Both Platforms
- [ ] Authentication works
- [ ] API calls succeed
- [ ] Image upload works
- [ ] Video playback works
- [ ] QR code generation works
- [ ] Payment flow works
- [ ] Deep links work
- [ ] Local storage works

## 🎯 Development Tips

### 1. Use Platform Checks When Needed
```dart
import 'dart:io';

if (Platform.isIOS) {
    // iOS-specific code
} else if (Platform.isAndroid) {
    // Android-specific code
}
```

### 2. Use Adaptive Widgets
```dart
// Will show Material on Android, Cupertino on iOS
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

Widget buildButton() {
  if (Platform.isIOS) {
    return CupertinoButton(child: Text('iOS'), onPressed: () {});
  }
  return ElevatedButton(child: Text('Android'), onPressed: () {});
}
```

### 3. Test on Real Devices
- iOS Simulator is fast but doesn't test camera, sensors
- Physical devices show real performance
- Test on different screen sizes

## 📊 Performance Monitoring

### Debug Mode
```bash
flutter run --verbose
```

### Profile Mode
```bash
flutter run --profile
```

### Release Mode
```bash
flutter run --release
```

## 🔐 Signing for Distribution

### iOS (App Store)
1. Create Apple Developer Account ($99/year)
2. Generate certificates in Apple Developer Console
3. Configure in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Select Runner → Signing & Capabilities
   - Select your team
   - Xcode handles provisioning profiles automatically

### Android (Play Store)
- Keep existing keystore configuration
- No changes needed from original setup

## 📱 Device-Specific Testing

### Test on Multiple iOS Versions
```bash
# iOS 12.0 (minimum)
# iOS 14.0 (common)
# iOS 15.0 (common)
# iOS 16.0+ (latest)
```

### Test on Multiple Screen Sizes
- iPhone SE (small)
- iPhone 14 Pro (standard)
- iPhone 14 Pro Max (large)
- iPad (tablet)

## 🌐 Environment Variables

Both platforms use the same `.env` file:
```bash
# No changes needed
# .env file works on both Android and iOS
```

## 🚨 Important Notes

1. **macOS Required**: iOS development requires macOS
2. **Xcode Required**: Free from Mac App Store
3. **Apple ID**: Free for development, $99/year for distribution
4. **No Breaking Changes**: All Android code still works
5. **Shared Codebase**: Same Dart code for both platforms

## 📞 Getting Help

### Check Status
```bash
flutter doctor -v
```

### Check Device Logs
```bash
# iOS
flutter logs -d iphone

# Android
flutter logs -d android
```

### Debug Information
```bash
# Analyze project
flutter analyze

# Check for updates
flutter upgrade
```

## ✅ Success Criteria

Your iOS setup is successful when:
- [x] `flutter doctor` shows no iOS issues
- [x] `flutter emulators` lists iOS simulators
- [x] `flutter run` launches app on iOS simulator
- [x] All features work on iOS
- [x] No Android functionality is broken

## 🎉 You're Ready!

The EventBn mobile app is now fully configured for both Android and iOS development. All features work on both platforms with the same codebase.

### Next Steps:
1. Run `cd ios && pod install` (one time)
2. Run `flutter run -d iphone` (test on iOS)
3. Run `flutter run -d android` (verify Android still works)
4. Start developing cross-platform features!

---

**Need Help?** Check the full documentation in `IOS_SETUP_COMPLETE.md`

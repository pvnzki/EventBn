# 🚀 Quick Start Guide for macOS Developers

## ⚡ TL;DR - Get iOS Running in 5 Minutes

```bash
# 1. Navigate to project
cd "path/to/EventBn/mobile-app"

# 2. Install iOS dependencies
cd ios && pod install && cd ..

# 3. Run on iOS Simulator
flutter run -d iphone

# Done! App should launch in iOS Simulator
```

---

## 📋 Prerequisites Checklist

Before starting, verify you have:

- [ ] macOS computer (required for iOS development)
- [ ] Xcode installed (`xcode-select --install`)
- [ ] Flutter SDK installed and in PATH
- [ ] CocoaPods installed (`sudo gem install cocoapods`)
- [ ] At least one iOS Simulator configured

### Verify Your Setup
```bash
# Check Flutter is working
flutter doctor -v

# Check for iOS devices
flutter devices

# Expected output should show iPhone simulators
```

---

## 🏃 Step-by-Step First Run

### Step 1: Get Dependencies
```bash
cd mobile-app
flutter pub get
```

### Step 2: Install iOS Pods
```bash
cd ios
pod install
cd ..
```
**⏱️ Takes:** ~2-5 minutes  
**Creates:** `ios/Podfile.lock` and `ios/Pods/` directory

### Step 3: Launch iOS Simulator
```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator (or open Xcode → Window → Devices and Simulators)
open -a Simulator
```

### Step 4: Run the App
```bash
flutter run -d iphone
```
**⏱️ First build takes:** ~5-10 minutes  
**Subsequent builds:** ~30 seconds

---

## 🧪 Testing Checklist

Once the app launches, test these features:

### Core Features
- [ ] Browse events (home screen)
- [ ] View event details
- [ ] Select seats (if event has seating)
- [ ] Process payment (test mode)
- [ ] View tickets with QR codes
- [ ] Update profile
- [ ] Upload profile picture

### iOS-Specific Features
- [ ] Camera permission dialog
- [ ] Photo library permission dialog
- [ ] Location permission dialog (if applicable)
- [ ] Deep linking (test: `xcrun simctl openurl booted eventbooking://event/123`)

---

## 🔍 Common Issues & Solutions

### Issue: "pod: command not found"
```bash
# Install CocoaPods
sudo gem install cocoapods

# If using Apple Silicon Mac
sudo gem install ffi
pod install
```

### Issue: "No devices found"
```bash
# Open Xcode to install simulators
open -a Xcode

# Go to: Xcode → Settings → Platforms
# Download iOS Simulator if needed
```

### Issue: Build fails with "Signing for Runner requires a development team"
```
Solution:
1. Open ios/Runner.xcworkspace in Xcode
2. Select Runner project
3. Go to "Signing & Capabilities" tab
4. Enable "Automatically manage signing"
5. Select your team (or use personal team)
```

### Issue: "Multiple commands produce..."
```bash
# Clean and rebuild
flutter clean
cd ios && pod deintegrate && pod install && cd ..
flutter run
```

---

## 📱 Running on Physical Device

### Prerequisites
- Apple Developer account (free or paid)
- iPhone/iPad connected via USB
- Device in Developer Mode

### Steps
```bash
# 1. Connect device
# 2. Trust the computer on device
# 3. List connected devices
flutter devices

# 4. Run on your device
flutter run -d <device-id>

# Example:
flutter run -d "iPhone 14"
```

### Enable Developer Mode on Device
```
iOS 16+:
Settings → Privacy & Security → Developer Mode → ON
(Device will restart)
```

---

## 🏗️ Building for Release

### Debug Build (for testing)
```bash
flutter build ios --debug
```

### Release Build (for App Store)
```bash
flutter build ios --release
```

### Generate IPA (for distribution)
```bash
flutter build ipa --release

# IPA location:
# build/ios/ipa/event_booking_app.ipa
```

---

## 🎨 Customize App Icons

### Quick Method
1. Open `ios/Runner/Assets.xcassets/AppIcon.appiconset` in Finder
2. Replace icon PNG files with EventBn branded icons
3. Keep same filenames and sizes

### Required Sizes
```
Icon-App-20x20@2x.png       → 40x40 px
Icon-App-20x20@3x.png       → 60x60 px
Icon-App-29x29@2x.png       → 58x58 px
Icon-App-29x29@3x.png       → 87x87 px
Icon-App-40x40@2x.png       → 80x80 px
Icon-App-40x40@3x.png       → 120x120 px
Icon-App-60x60@2x.png       → 120x120 px
Icon-App-60x60@3x.png       → 180x180 px
Icon-App-1024x1024@1x.png   → 1024x1024 px (App Store)
```

### Pro Method
Use [App Icon Generator](https://www.appicon.co/) or similar tool:
1. Upload your 1024x1024 master icon
2. Download iOS icon set
3. Replace files in `Assets.xcassets/AppIcon.appiconset/`

---

## 🚀 Hot Reload & Development

### During Development
```bash
# Start app in debug mode
flutter run -d iphone

# Then use these shortcuts:
r  → Hot reload (fast, preserves state)
R  → Hot restart (full restart)
p  → Show performance overlay
o  → Toggle platform (iOS/Android)
q  → Quit

# Press 'h' in terminal to see all shortcuts
```

### Debugging
```bash
# Run with verbose logging
flutter run -v -d iphone

# View logs only
flutter logs

# Clear cache and rebuild
flutter clean && flutter run
```

---

## 📊 Performance Testing

### Check App Size
```bash
flutter build ios --release --split-debug-info
flutter build ipa --release

# View size
ls -lh build/ios/ipa/
```

### Profile Performance
```bash
# Run in profile mode
flutter run --profile -d iphone

# Then use DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 📲 Deep Link Testing

### Test Deep Links in Simulator
```bash
# Start the app first
flutter run -d iphone

# In another terminal, open deep links:
xcrun simctl openurl booted eventbooking://event/123
xcrun simctl openurl booted eventbn://ticket/456
xcrun simctl openurl booted eventbooking://profile
```

### Test Universal Links
```bash
# Test HTTPS links (requires proper setup)
xcrun simctl openurl booted https://eventbn.com/event/123
```

---

## 🧹 Clean Build (When Things Go Wrong)

### Nuclear Option - Full Clean
```bash
# Navigate to project
cd mobile-app

# Clean Flutter
flutter clean

# Remove iOS build artifacts
rm -rf ios/Pods
rm -rf ios/.symlinks
rm ios/Podfile.lock

# Reinstall everything
flutter pub get
cd ios && pod install && cd ..

# Rebuild
flutter run -d iphone
```

---

## 📚 Essential Commands Reference

```bash
# Project Setup
flutter pub get                      # Get dependencies
cd ios && pod install && cd ..       # Install iOS pods

# Running
flutter run                          # Run on default device
flutter run -d iphone               # Run on iOS simulator
flutter run -d <device-id>          # Run on specific device
flutter run --release               # Run release build

# Building
flutter build ios                    # Build iOS app
flutter build ipa                    # Build IPA for distribution

# Cleaning
flutter clean                        # Clean build cache
pod deintegrate                     # Remove pods (run in ios/)

# Debugging
flutter logs                         # View logs
flutter doctor -v                    # Check Flutter setup
flutter devices                      # List available devices

# Testing
flutter test                         # Run unit tests
flutter test integration_test/       # Run integration tests
```

---

## 🎯 Next Steps After First Run

1. **Verify all features work** - Go through testing checklist above
2. **Customize branding** - Replace app icons with EventBn logo
3. **Test on physical device** - Connect iPhone and test
4. **Set up code signing** - Configure Apple Developer team
5. **Test payments** - Verify PayHere SDK works on iOS
6. **Prepare for App Store** - Follow IOS_SETUP_COMPLETE.md guide

---

## 💡 Pro Tips

### Speed Up Builds
```bash
# Use iOS Simulator instead of device for development
# Simulators build faster and don't require code signing

# Keep simulator running between builds
# Don't close it - reuse for hot reload
```

### Productivity Shortcuts
```bash
# Create alias in ~/.zshrc or ~/.bash_profile
alias frun='flutter run -d iphone'
alias fbuild='flutter build ios --release'
alias fclean='flutter clean && flutter pub get'

# Then just use:
frun
```

### Xcode Integration
```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Use Xcode for:
# - Code signing setup
# - Capabilities configuration
# - Asset management
# - Advanced debugging
```

---

## 📞 Get Help

### If Stuck
1. Check `flutter doctor -v` output
2. Review error messages carefully
3. Search Flutter GitHub issues
4. Check Stack Overflow
5. Review IOS_SETUP_COMPLETE.md for detailed info

### Useful Links
- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos)
- [Xcode Documentation](https://developer.apple.com/documentation/xcode)
- [CocoaPods Guides](https://guides.cocoapods.org/)

---

## ✅ Success Indicators

You'll know everything is working when:
- ✅ `flutter doctor` shows no iOS errors
- ✅ `pod install` completes without errors
- ✅ App launches in iOS Simulator
- ✅ All features work as expected
- ✅ Hot reload works during development
- ✅ Can build release IPA

---

**Happy iOS Development! 🎉**

*This is a living document. Update as you discover better workflows.*

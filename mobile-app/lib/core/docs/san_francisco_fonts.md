# San Francisco Font Integration Guide

This document explains how to use San Francisco fonts throughout the EventBn app.

## Overview

The app now uses San Francisco fonts to match Apple's design language:
- **SF Pro Display**: For headlines, titles, and larger text elements
- **SF Pro Text**: For body text, labels, and smaller text elements

## Usage

### 1. Using Theme Text Styles (Recommended)

Use the built-in theme text styles that automatically use San Francisco fonts:

```dart
// Headlines and titles
Text('Event Title', style: Theme.of(context).textTheme.headlineLarge)
Text('Section Header', style: Theme.of(context).textTheme.headlineMedium)
Text('Card Title', style: Theme.of(context).textTheme.titleLarge)

// Body text
Text('Main content text', style: Theme.of(context).textTheme.bodyLarge)
Text('Secondary text', style: Theme.of(context).textTheme.bodyMedium)
Text('Caption text', style: Theme.of(context).textTheme.bodySmall)

// Labels and buttons
Text('Button Label', style: Theme.of(context).textTheme.labelLarge)
Text('Form Label', style: Theme.of(context).textTheme.labelMedium)
```

### 2. Using SFFont Utility Class

For more control, use the `SFFont` utility class:

```dart
import 'package:event_booking_app/core/utils/sf_font.dart';

// Quick styles
Text('Title', style: SFFont.headlineLarge(color: Colors.black))
Text('Body', style: SFFont.bodyMedium(color: Colors.grey))

// Custom weights
Text('Thin text', style: SFFont.thin(fontSize: 16, color: Colors.blue))
Text('Bold text', style: SFFont.bold(fontSize: 18, color: Colors.red))
Text('Medium text', style: SFFont.medium(fontSize: 14))
```

### 3. Manual Font Family (Use sparingly)

```dart
TextStyle(
  fontFamily: 'SF Pro Display', // For larger text
  fontSize: 24,
  fontWeight: FontWeight.w600,
)

TextStyle(
  fontFamily: 'SF Pro Text', // For body text
  fontSize: 16,
  fontWeight: FontWeight.w400,
)
```

## Font Hierarchy

### Display Styles (SF Pro Display)
- `displayLarge`: 57px - App titles, hero text
- `displayMedium`: 45px - Large sections
- `displaySmall`: 36px - Page headers

### Headlines (SF Pro Display)
- `headlineLarge`: 32px, Semibold - Main headers
- `headlineMedium`: 28px, Semibold - Sub headers  
- `headlineSmall`: 24px, Semibold - Card headers

### Titles (SF Pro Display)
- `titleLarge`: 22px, Semibold - Dialog titles
- `titleMedium`: 16px, Semibold - List items
- `titleSmall`: 14px, Semibold - Small headers

### Body Text (SF Pro Text)
- `bodyLarge`: 16px, Regular - Main content
- `bodyMedium`: 14px, Regular - Secondary content
- `bodySmall`: 12px, Regular - Captions

### Labels (SF Pro Text)
- `labelLarge`: 14px, Medium - Button text
- `labelMedium`: 12px, Medium - Form labels
- `labelSmall`: 11px, Medium - Small indicators

## Font Weights

San Francisco supports these weights:
- `FontWeight.w100` - Ultralight
- `FontWeight.w200` - Thin
- `FontWeight.w300` - Light
- `FontWeight.w400` - Regular
- `FontWeight.w500` - Medium
- `FontWeight.w600` - Semibold
- `FontWeight.w700` - Bold
- `FontWeight.w800` - Heavy
- `FontWeight.w900` - Black

## Best Practices

### 1. Choose the Right Font
- Use **SF Pro Display** for headlines, titles, and UI elements
- Use **SF Pro Text** for body text and reading content

### 2. Weight Selection
- **Regular (400)**: Body text, normal content
- **Medium (500)**: Important labels, emphasized text
- **Semibold (600)**: Headlines, section headers
- **Bold (700)**: Very important text, warnings

### 3. Size Guidelines
- **12px and below**: Use SF Pro Text
- **13px and above**: Either font works, choose based on context
- **20px and above**: SF Pro Display usually works better

### 4. Platform Considerations
- On iOS: San Francisco fonts are built-in and will render natively
- On Android: Custom font files are used for consistency
- On Web: Falls back to system fonts if files aren't loaded

## Examples

### Event Card
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Event Title',
      style: SFFont.titleLarge(color: Colors.black),
    ),
    Text(
      'Event description and details...',
      style: SFFont.bodyMedium(color: Colors.grey[700]),
    ),
    Text(
      'Oct 15, 2024',
      style: SFFont.bodySmall(color: Colors.grey[500]),
    ),
  ],
)
```

### Button
```dart
ElevatedButton(
  onPressed: () {},
  child: Text(
    'Book Now',
    style: SFFont.labelLarge(color: Colors.white),
  ),
)
```

### App Bar
```dart
AppBar(
  title: Text(
    'Events',
    style: SFFont.titleLarge(),
  ),
)
```

## Font Installation

The font files should be placed in `assets/fonts/`:
- SF-Pro-Display-Regular.ttf
- SF-Pro-Display-Medium.ttf
- SF-Pro-Display-Semibold.ttf
- SF-Pro-Display-Bold.ttf
- SF-Pro-Text-Regular.ttf
- SF-Pro-Text-Medium.ttf
- SF-Pro-Text-Semibold.ttf
- SF-Pro-Text-Bold.ttf

If font files are not available, the app will gracefully fall back to system fonts.

## Troubleshooting

### Fonts Not Showing
1. Check that font files are in `assets/fonts/`
2. Verify `pubspec.yaml` font configuration
3. Run `flutter clean && flutter pub get`
4. Check font family names match exactly

### Performance
- San Francisco fonts are optimized for performance
- Use theme text styles when possible for better caching
- Avoid creating too many custom TextStyle objects

### Testing
Test on multiple devices to ensure fonts render correctly:
- iOS Simulator
- Android Emulator  
- Physical devices
- Different screen densities
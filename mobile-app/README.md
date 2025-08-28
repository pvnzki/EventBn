# Event Booking Mobile App

A Flutter-based mobile application for browsing, booking, and managing event tickets. This app is part of the larger Event Ticketing and Management Platform.

## Features

- **User Authentication**: Login and registration functionality
- **Event Browsing**: Browse and search for events
- **Event Details**: View detailed information about events
- **Ticket Booking**: Purchase tickets using Stripe payment integration
- **My Tickets**: View purchased tickets and upcoming events
- **User Profile**: Manage user account and preferences

## Architecture

This project follows **Clean Architecture** principles with the following structure:

### Folder Structure

```
lib/
├── main.dart                          # App entry point
├── core/                              # Core functionality
│   ├── config/
│   │   └── app_config.dart           # App configuration and environment variables
│   ├── routes/
│   │   └── app_router.dart           # GoRouter configuration
│   ├── theme/
│   │   └── app_theme.dart            # App theme and styling
│   ├── utils/
│   │   └── helpers.dart              # Utility functions and helpers
│   └── constants.dart                # App constants
├── features/                          # Feature-based modules
│   ├── auth/                         # Authentication feature
│   │   ├── models/
│   │   │   └── user_model.dart       # User data model
│   │   ├── providers/
│   │   │   └── auth_provider.dart    # Authentication state management
│   │   ├── screens/
│   │   │   ├── login_screen.dart     # Login UI
│   │   │   └── register_screen.dart  # Registration UI
│   │   └── services/
│   │       └── auth_service.dart     # Authentication API service
│   ├── events/                       # Events feature
│   │   ├── models/
│   │   │   └── event_model.dart      # Event data model
│   │   ├── providers/
│   │   │   └── event_provider.dart   # Event state management
│   │   ├── screens/
│   │   │   ├── home_screen.dart      # Home/Events listing
│   │   │   ├── event_details_screen.dart # Event details
│   │   │   └── search_screen.dart    # Event search
│   │   └── services/
│   │       └── event_service.dart    # Event API service
│   ├── tickets/                      # Tickets feature
│   │   ├── models/
│   │   │   └── ticket_model.dart     # Ticket data model
│   │   ├── providers/
│   │   │   └── ticket_provider.dart  # Ticket state management
│   │   └── screens/
│   │       └── my_tickets_screen.dart # User tickets
│   ├── payment/                      # Payment feature
│   │   ├── providers/
│   │   │   └── payment_provider.dart # Payment state management
│   │   └── screens/
│   │       └── checkout_screen.dart  # Payment checkout
│   └── profile/                      # Profile feature
│       └── screens/
│           └── profile_screen.dart   # User profile
├── services/                         # Global services
│   └── stripe_service.dart          # Stripe payment service
└── common_widgets/                   # Reusable UI components
    ├── custom_text_field.dart       # Custom text input
    ├── custom_button.dart           # Custom button
    └── bottom_nav_bar.dart          # Bottom navigation
```

## Dependencies

### Main Dependencies

- `flutter`: Flutter SDK
- `provider`: State management
- `go_router`: Navigation and routing
- `http`: HTTP client for API calls
- `flutter_stripe`: Stripe payment integration
- `shared_preferences`: Local storage
- `json_annotation`: JSON serialization
- `cached_network_image`: Image caching
- `intl`: Internationalization

### Dev Dependencies

- `build_runner`: Code generation
- `json_serializable`: JSON serialization code generation
- `flutter_lints`: Linting rules

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator (for iOS development)
- Android Emulator (for Android development)

### Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd mobile-app
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Configure environment variables**

   - Copy `.env.example` to `.env`
   - Update the environment variables with your actual values:

   ```
   BASE_URL=your_backend_api_url
   STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
   STRIPE_SECRET_KEY=your_stripe_secret_key
   ```

4. **Generate code (for models)**

```bash
flutter packages pub run build_runner build
```

5. **Run the app**

```bash
flutter run
```

## Configuration

### Environment Variables

The app uses environment variables stored in `.env` file:

- `BASE_URL`: Backend API base URL
- `STRIPE_PUBLISHABLE_KEY`: Stripe publishable key for payments
- `STRIPE_SECRET_KEY`: Stripe secret key (use with caution)

### State Management

The app uses Provider for state management with the following providers:

- `AuthProvider`: Manages authentication state
- `EventProvider`: Manages event data and state
- `TicketProvider`: Manages user tickets
- `PaymentProvider`: Manages payment processing

### Navigation

The app uses GoRouter for navigation with the following routes:

- `/login` - Login screen
- `/register` - Registration screen
- `/home` - Home screen (events listing)
- `/search` - Event search
- `/tickets` - User tickets
- `/profile` - User profile
- `/event/:eventId` - Event details
- `/checkout/:eventId` - Payment checkout

## API Integration

The app integrates with a backend API for:

- User authentication (login/register)
- Event data (browsing, search, details)
- Ticket purchasing
- User profile management

### API Endpoints Structure

```
/api/auth/login           # POST - User login
/api/auth/register        # POST - User registration
/api/auth/me             # GET - Current user data
/api/events              # GET - List events
/api/events/:id          # GET - Event details
/api/events/search       # GET - Search events
/api/tickets             # GET/POST - User tickets
/api/payments            # POST - Process payments
```

## Payment Integration

The app integrates with Stripe for payment processing:

1. **Setup**: Configure Stripe keys in environment variables
2. **Payment Flow**:
   - Create payment intent on backend
   - Use Stripe SDK to collect payment method
   - Confirm payment through Stripe
   - Update ticket status on backend

## Development Guidelines

### Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### File Organization

- Group related functionality in features
- Keep models, providers, services, and screens separated
- Use barrel exports where appropriate
- Follow the established folder structure

### State Management Best Practices

- Use Provider for state management
- Keep providers focused on single responsibility
- Handle loading and error states appropriately
- Avoid unnecessary rebuilds

## Building for Production

### Android

```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Testing

### Run Tests

```bash
flutter test
```

### Run Integration Tests

```bash
flutter drive --target=test_driver/app.dart
```

## Deployment

### Android Play Store

1. Build release APK/App Bundle
2. Sign the app with release keystore
3. Upload to Google Play Console

### iOS App Store

1. Build release IPA
2. Sign with distribution certificate
3. Upload to App Store Connect

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact [your-email@example.com]

---

**Note**: This is the initial project structure. UI implementation and full functionality will be added in subsequent development phases.

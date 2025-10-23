# EventBn Mobile App Tests

This directory contains all tests for the EventBn mobile application.

## Test Structure

```
test/
├── unit/              # Unit tests for individual components
│   ├── models/        # Model tests
│   ├── providers/     # Provider/state management tests
│   └── services/      # Service layer tests
├── widget/            # Widget tests
│   ├── screens/       # Screen widget tests
│   └── widgets/       # Component widget tests
├── integration/       # Integration tests
└── helpers/           # Test helpers and mocks
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/unit/providers/ticket_provider_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Run integration tests
```bash
flutter test integration_test/app_test.dart
```

## Test Coverage Goals

- Unit Tests: >80% coverage
- Widget Tests: Critical UI components
- Integration Tests: Main user flows

## Key Test Areas

1. **Authentication Flow**
   - Login/logout
   - Token management
   - User state

2. **Ticket Management**
   - Fetching tickets
   - Cancellation
   - QR code display

3. **Event Discovery**
   - Event listing
   - Search/filter
   - Event details

4. **Booking Flow**
   - Seat selection
   - Payment processing
   - Order confirmation

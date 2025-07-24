# Event Booking Mobile App - File Structure

```
mobile-app/
├── .env                              # Environment variables (API keys, URLs)
├── pubspec.yaml                      # Flutter project configuration and dependencies
├── README.md                         # Project documentation
│
├── lib/                              # Main source code directory
│   ├── main.dart                     # App entry point with providers and routing setup
│   │
│   ├── core/                         # Core functionality (shared across features)
│   │   ├── config/
│   │   │   └── app_config.dart       # App configuration (environment variables, constants)
│   │   ├── routes/
│   │   │   └── app_router.dart       # GoRouter configuration (navigation routes)
│   │   ├── theme/
│   │   │   └── app_theme.dart        # App theme (colors, typography, component themes)
│   │   ├── utils/
│   │   │   └── helpers.dart          # Utility functions (validation, formatting, UI helpers)
│   │   └── constants.dart            # App-wide constants (API endpoints, validation rules)
│   │
│   ├── features/                     # Feature-based architecture
│   │   │
│   │   ├── auth/                     # Authentication feature
│   │   │   ├── models/
│   │   │   │   └── user_model.dart   # User data model with JSON serialization
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart # Authentication state management (login, register, logout)
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart  # Login UI with form validation
│   │   │   │   └── register_screen.dart # Registration UI (placeholder)
│   │   │   └── services/
│   │   │       └── auth_service.dart  # Authentication API service (HTTP calls, token management)
│   │   │
│   │   ├── events/                   # Events browsing and details feature
│   │   │   ├── models/
│   │   │   │   └── event_model.dart  # Event and TicketType models with JSON serialization
│   │   │   ├── providers/
│   │   │   │   └── event_provider.dart # Event state management (fetch, search, current event)
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart  # Home screen with events listing (placeholder)
│   │   │   │   ├── event_details_screen.dart # Event details screen (placeholder)
│   │   │   │   └── search_screen.dart # Event search screen (placeholder)
│   │   │   └── services/
│   │   │       └── event_service.dart # Event API service (fetch events, search, categories)
│   │   │
│   │   ├── tickets/                  # User tickets management feature
│   │   │   ├── models/
│   │   │   │   └── ticket_model.dart # Ticket model with status enum
│   │   │   ├── providers/
│   │   │   │   └── ticket_provider.dart # Ticket state management (user tickets, upcoming/past)
│   │   │   └── screens/
│   │   │       └── my_tickets_screen.dart # User tickets screen (placeholder)
│   │   │
│   │   ├── payment/                  # Payment processing feature
│   │   │   ├── providers/
│   │   │   │   └── payment_provider.dart # Payment state management (Stripe integration)
│   │   │   └── screens/
│   │   │       └── checkout_screen.dart # Payment checkout screen (placeholder)
│   │   │
│   │   └── profile/                  # User profile management feature
│   │       └── screens/
│   │           └── profile_screen.dart # User profile screen (placeholder)
│   │
│   ├── services/                     # Global services (shared across features)
│   │   └── stripe_service.dart       # Stripe payment service (payment intents, methods)
│   │
│   └── common_widgets/               # Reusable UI components
│       ├── custom_text_field.dart   # Custom text input with validation and styling
│       ├── custom_button.dart       # Custom button with loading state
│       └── bottom_nav_bar.dart      # Bottom navigation bar with routing
│
├── assets/                           # Static assets
│   ├── images/                       # App images and illustrations
│   ├── icons/                        # App icons and graphics
│   └── fonts/                        # Custom fonts (if any)
│
└── test/                            # Test files
    └── (test files will be added later)
```

## File Purposes and Responsibilities

### Core Files

**main.dart**

- App entry point
- Provider setup (AuthProvider, EventProvider, etc.)
- Stripe initialization
- MaterialApp with routing configuration

**core/config/app_config.dart**

- Environment variable management
- API URLs and configuration
- App constants and settings

**core/routes/app_router.dart**

- GoRouter configuration
- Route definitions and navigation
- Bottom navigation integration

**core/theme/app_theme.dart**

- Light and dark theme definitions
- Color schemes and typography
- Component styling (buttons, text fields, etc.)

### Feature-Based Architecture

Each feature follows the same structure:

**Models** (`models/`)

- Data classes with JSON serialization
- Business logic and computed properties
- Type-safe data representation

**Providers** (`providers/`)

- State management using Provider package
- API call coordination
- Loading and error state handling

**Screens** (`screens/`)

- UI components and layouts
- User interaction handling
- Provider consumption for data

**Services** (`services/`)

- HTTP API communication
- Data transformation
- Error handling and retry logic

### Global Services

**services/stripe_service.dart**

- Stripe SDK integration
- Payment intent creation
- Payment method handling
- Payment confirmation

### Common Widgets

**common_widgets/**

- Reusable UI components
- Consistent styling across the app
- Shared functionality (forms, buttons, navigation)

## Key Features by File

### Authentication Flow

- `auth/screens/login_screen.dart`: Login form with validation
- `auth/providers/auth_provider.dart`: Login/logout state management
- `auth/services/auth_service.dart`: API calls for authentication
- `auth/models/user_model.dart`: User data structure

### Event Browsing

- `events/screens/home_screen.dart`: Events listing and discovery
- `events/screens/event_details_screen.dart`: Detailed event information
- `events/providers/event_provider.dart`: Event data management
- `events/services/event_service.dart`: Event API integration

### Ticket Management

- `tickets/screens/my_tickets_screen.dart`: User ticket history
- `tickets/models/ticket_model.dart`: Ticket data structure
- `tickets/providers/ticket_provider.dart`: Ticket state management

### Payment Processing

- `payment/screens/checkout_screen.dart`: Payment form and processing
- `payment/providers/payment_provider.dart`: Payment state management
- `services/stripe_service.dart`: Stripe integration

## Development Status

✅ **Completed**

- Project structure and folder organization
- Core configuration and routing
- Model definitions with JSON serialization
- Provider setup for state management
- Service layer architecture
- Basic UI components (placeholders)

🚧 **In Progress**

- UI implementation for all screens
- API integration testing
- Payment flow implementation

📋 **Planned**

- Unit and integration tests
- Error handling improvements
- Performance optimizations
- Accessibility features

---

This structure follows Flutter best practices and Clean Architecture principles, making the codebase maintainable, testable, and scalable.

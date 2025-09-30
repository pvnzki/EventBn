# Test Structure Documentation

This document explains the organized test structure for the EventBn backend API.

## Folder Structure

```
tests/
├── unit/                    # Unit tests for individual components
│   ├── controllers/         # Controller unit tests
│   │   └── analytics.test.js
│   ├── services/           # Service layer unit tests
│   │   ├── analytics.test.js
│   │   ├── auth.test.js
│   │   ├── events.test.js
│   │   ├── organizations.test.js
│   │   ├── posts.test.js
│   │   ├── users.test.js
│   │   └── searchLogs.test.js
│   └── middleware/         # Middleware unit tests
│       └── auth.test.js
├── integration/            # Integration tests for API endpoints
│   ├── auth/              # Authentication integration tests
│   │   └── auth.test.js
│   ├── events/            # Events integration tests
│   │   └── events.test.js
│   ├── users/             # Users integration tests
│   │   └── users.test.js
│   ├── basic-api.test.js  # Core API integration tests
│   ├── cross-service.test.js # Cross-service integration tests
│   └── setup.js           # Integration test setup
├── fixtures/              # Test data and mock files
│   └── prisma-mock.js     # Prisma database mocking utilities
├── utils/                 # Test utilities and helpers
└── config/                # Test configuration files
    ├── global-setup.js    # Jest global setup
    ├── global-teardown.js # Jest global teardown
    ├── jest.setup.js      # Jest test setup
    └── test-env.js        # Test environment configuration
```

## Test Types

### Unit Tests (`/unit`)

- Test individual components in isolation
- Mock external dependencies
- Fast execution
- High coverage of business logic

**Run unit tests only:**

```bash
npm test -- tests/unit
```

### Integration Tests (`/integration`)

- Test API endpoints end-to-end
- Test interaction between components
- Use mocked database for consistency
- Validate API contracts and responses

**Run integration tests only:**

```bash
npm test -- tests/integration
```

## Test Utilities

### Fixtures (`/fixtures`)

- **prisma-mock.js**: Comprehensive Prisma database mocking for isolated testing
- Provides consistent test data across all tests
- Eliminates need for real database in testing

### Configuration (`/config`)

- **test-env.js**: Environment setup (NODE_ENV, JWT_SECRET, etc.)
- **global-setup.js**: Jest global setup for test environment
- **global-teardown.js**: Jest global cleanup
- **jest.setup.js**: Jest-specific test setup

## Running Tests

**All tests:**

```bash
npm test
```

**Specific test file:**

```bash
npm test -- tests/unit/services/auth.test.js
```

**With coverage:**

```bash
npm test -- --coverage
```

**Watch mode:**

```bash
npm test -- --watch
```

## Best Practices

1. **Unit Tests**: Focus on individual function/method behavior
2. **Integration Tests**: Focus on API contract and workflow validation
3. **Mocking**: Use fixtures for consistent test data
4. **Isolation**: Each test should be independent and idempotent
5. **Coverage**: Aim for high coverage but focus on quality over quantity

## Current Status

✅ **Integration Tests**: 22/22 passing (100% success rate)

- Authentication endpoints
- Event management
- Error handling
- CORS headers
- Validation

⏳ **Unit Tests**: Available but need review for new structure

- Service layer tests
- Controller tests
- Middleware tests

#!/bin/bash

# EventBn Mobile App Test Runner
# Run all tests with coverage

echo "🧪 Running EventBn Mobile App Tests..."
echo "======================================"

# Clean previous build artifacts
echo "🧹 Cleaning..."
flutter clean
flutter pub get

# Run unit and widget tests with coverage
echo ""
echo "📊 Running tests with coverage..."
flutter test --coverage

# Check if coverage was generated
if [ -f "coverage/lcov.info" ]; then
    echo ""
    echo "✅ Tests completed! Coverage report generated."
    echo ""
    echo "📈 To view coverage report:"
    echo "   1. Install lcov: brew install lcov (Mac) or apt-get install lcov (Linux)"
    echo "   2. Generate HTML report: genhtml coverage/lcov.info -o coverage/html"
    echo "   3. Open: open coverage/html/index.html"
    echo ""
else
    echo "⚠️  Coverage report not generated"
fi

# Run integration tests (optional - requires device/emulator)
echo ""
read -p "Run integration tests? (requires device/emulator) [y/N]: " run_integration
if [[ $run_integration =~ ^[Yy]$ ]]; then
    echo "🔄 Running integration tests..."
    flutter test integration_test/
fi

echo ""
echo "✨ Test run complete!"

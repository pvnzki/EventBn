# EventBn Mobile App Test Runner (PowerShell)
# Run all tests with coverage

Write-Host "🧪 Running EventBn Mobile App Tests..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Clean previous build artifacts
Write-Host "🧹 Cleaning..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host ""
Write-Host "📊 Running tests with coverage..." -ForegroundColor Yellow
flutter test --coverage

# Check if coverage was generated
if (Test-Path "coverage/lcov.info") {
    Write-Host ""
    Write-Host "✅ Tests completed! Coverage report generated." -ForegroundColor Green
    Write-Host ""
    Write-Host "📈 Coverage file: coverage/lcov.info" -ForegroundColor Cyan
    
    # Try to generate HTML report if genhtml is available
    if (Get-Command genhtml -ErrorAction SilentlyContinue) {
        Write-Host "Generating HTML coverage report..." -ForegroundColor Yellow
        genhtml coverage/lcov.info -o coverage/html
        Write-Host "✅ HTML report generated at coverage/html/index.html" -ForegroundColor Green
    } else {
        Write-Host "💡 Install lcov to generate HTML reports:" -ForegroundColor Yellow
        Write-Host "   - Windows: choco install lcov" -ForegroundColor Gray
        Write-Host "   - Or use online tools to view lcov.info" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  Coverage report not generated" -ForegroundColor Red
}

# Run integration tests (optional - requires device/emulator)
Write-Host ""
$runIntegration = Read-Host "Run integration tests? (requires device/emulator) [y/N]"
if ($runIntegration -eq "y" -or $runIntegration -eq "Y") {
    Write-Host "🔄 Running integration tests..." -ForegroundColor Yellow
    flutter test integration_test/
}

Write-Host ""
Write-Host "✨ Test run complete!" -ForegroundColor Green

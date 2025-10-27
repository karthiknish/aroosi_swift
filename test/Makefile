# Aroosi iOS Test Suite Makefile

.PHONY: test test-unit test-integration test-ui test-coverage test-clean test-help

# Default target
test: test-unit test-integration

# Run all unit tests
test-unit:
	@echo "🧪 Running Unit Tests..."
	cd .. && swift test --filter AroosiAppTests.AuthenticationTests
	cd .. && swift test --filter AroosiAppTests.DashboardTests
	cd .. && swift test --filter AroosiAppTests.ChatTests
	@echo "✅ Unit Tests Complete"

# Run integration tests
test-integration:
	@echo "🔗 Running Integration Tests..."
	cd .. && swift test --filter AroosiAppTests.FirebaseIntegrationTests
	@echo "✅ Integration Tests Complete"

# Run UI tests (requires simulator)
test-ui:
	@echo "📱 Running UI Tests..."
	xcodebuild test \
		-project ../native_ios/AroosiApp.xcodeproj \
		-scheme AroosiApp \
		-destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
		-only-testing:AroosiAppUITests
	@echo "✅ UI Tests Complete"

# Run tests with coverage
test-coverage:
	@echo "📊 Running Tests with Coverage..."
	cd .. && swift test --enable-code-coverage
	@echo "📈 Generating Coverage Report..."
	cd .. && xcrun llvm-cov report \
		.build/debug/AroosiAppTests.xctest/Contents/MacOS/AroosiAppTests \
		-instr-profile=.build/debug/codecov/default.profdata \
		-sources
	@echo "✅ Coverage Report Complete"

# Run performance tests
test-performance:
	@echo "⚡ Running Performance Tests..."
	cd .. && swift test --filter PerformanceTests
	@echo "✅ Performance Tests Complete"

# Run accessibility tests
test-accessibility:
	@echo "♿ Running Accessibility Tests..."
	cd .. && swift test --filter AccessibilityTests
	@echo "✅ Accessibility Tests Complete"

# Run tests in parallel
test-parallel:
	@echo "🚀 Running Tests in Parallel..."
	cd .. && swift test --parallel
	@echo "✅ Parallel Tests Complete"

# Run tests with verbose output
test-verbose:
	@echo "🔍 Running Tests with Verbose Output..."
	cd .. && swift test --verbose
	@echo "✅ Verbose Tests Complete"

# Run tests on specific simulator
test-simulator:
	@echo "📱 Running Tests on iPhone 15 Simulator..."
	xcodebuild test \
		-project ../native_ios/AroosiApp.xcodeproj \
		-scheme AroosiApp \
		-destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
	@echo "✅ Simulator Tests Complete"

# Run tests on multiple simulators
test-multiple-simulators:
	@echo "📱 Running Tests on Multiple Simulators..."
	xcodebuild test \
		-project ../native_ios/AroosiApp.xcodeproj \
		-scheme AroosiApp \
		-destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
		-destination 'platform=iOS Simulator,name=iPhone 15 Pro Max,OS=17.0'
	@echo "✅ Multiple Simulator Tests Complete"

# Clean test artifacts
test-clean:
	@echo "🧹 Cleaning Test Artifacts..."
	cd .. && swift package clean
	rm -rf ../native_ios/.build
	rm -rf ../native_ios/DerivedData
	rm -rf *.xcresult
	@echo "✅ Clean Complete"

# Generate test report
test-report:
	@echo "📊 Generating Test Report..."
	cd .. && swift test --enable-code-coverage > test-results.txt
	@echo "📋 Test Report Generated: test-results.txt"

# Watch mode for continuous testing
test-watch:
	@echo "👀 Starting Watch Mode..."
	cd .. && fswatch -o . | xargs -n1 -I{} swift test

# Quick test (unit only, no coverage)
test-quick:
	@echo "⚡ Running Quick Tests..."
	cd .. && swift test --skip-build
	@echo "✅ Quick Tests Complete"

# Test specific target
test-auth:
	@echo "🔐 Testing Authentication..."
	cd .. && swift test --filter AuthenticationTests
	@echo "✅ Auth Tests Complete"

test-dashboard:
	@echo "📊 Testing Dashboard..."
	cd .. && swift test --filter DashboardTests
	@echo "✅ Dashboard Tests Complete"

test-chat:
	@echo "💬 Testing Chat..."
	cd .. && swift test --filter ChatTests
	@echo "✅ Chat Tests Complete"

# Firebase-specific tests
test-firebase:
	@echo "🔥 Testing Firebase Integration..."
	cd .. && swift test --filter FirebaseIntegrationTests
	@echo "✅ Firebase Tests Complete"

# Help target
test-help:
	@echo "📚 Aroosi iOS Test Suite Help"
	@echo ""
	@echo "Available targets:"
	@echo "  test              - Run all unit and integration tests"
	@echo "  test-unit         - Run unit tests only"
	@echo "  test-integration  - Run integration tests only"
	@echo "  test-ui           - Run UI tests (requires simulator)"
	@echo "  test-coverage     - Run tests with coverage report"
	@echo "  test-performance  - Run performance tests"
	@echo "  test-accessibility- Run accessibility tests"
	@echo "  test-parallel     - Run tests in parallel"
	@echo "  test-verbose      - Run tests with verbose output"
	@echo "  test-simulator    - Run tests on specific simulator"
	@echo "  test-multiple-simulators - Run tests on multiple simulators"
	@echo "  test-clean        - Clean test artifacts"
	@echo "  test-report       - Generate test report"
	@echo "  test-watch        - Watch mode for continuous testing"
	@echo "  test-quick        - Quick tests (no build, no coverage)"
	@echo "  test-auth         - Test authentication module"
	@echo "  test-dashboard    - Test dashboard module"
	@echo "  test-chat         - Test chat module"
	@echo "  test-firebase     - Test Firebase integration"
	@echo "  test-help         - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make test-coverage"
	@echo "  make test-auth"
	@echo "  make test-clean && make test-coverage"

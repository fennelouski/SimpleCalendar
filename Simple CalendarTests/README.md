# Unit Testing Guide for Calendar Play

This document outlines our policies, procedures, and best practices for writing, maintaining, and executing unit tests in the Calendar Play project.

## Table of Contents
1. [Testing Framework](#testing-framework)
2. [Test Organization](#test-organization)
3. [Writing Tests](#writing-tests)
4. [Test Execution](#test-execution)
5. [Best Practices](#best-practices)
6. [Common Patterns](#common-patterns)
7. [Troubleshooting](#troubleshooting)

## Testing Framework

We use Apple's Testing framework (`import Testing`) which provides:
- Modern Swift testing syntax with `@Test` attributes
- Async/await support for asynchronous tests
- Improved error reporting and debugging
- Integration with Xcode's test runner

## Test Organization

### File Structure
```
Calendar PlayTests/
├── Simple_CalendarTests.swift     # Main test file
├── README.md                      # This documentation
└── [Additional test files as needed]
```

### Test Naming Convention
- Test methods use camelCase prefixed with `test`
- Test names should be descriptive and indicate what behavior is being tested
- Example: `testNavigateDateByWeekBackward()`

### Test Categories
- **Unit Tests**: Test individual functions and methods in isolation
- **Integration Tests**: Test interactions between components
- **UI Tests**: Test user interface interactions (separate target)

## Writing Tests

### Basic Test Structure

```swift
@Test func testDescriptiveName() async throws {
    // Given - Set up test preconditions
    let viewModel = CalendarViewModel()
    let calendar = Calendar(identifier: .gregorian)
    let testDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))!

    // When - Execute the code being tested
    viewModel.selectedDate = testDate
    viewModel.moveUpOneWeek()

    // Then - Verify the expected behavior
    let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!
    #expect(calendar.isDate(viewModel.selectedDate!, inSameDayAs: expectedDate))
}
```

### Test Components

#### Given (Setup)
- Initialize objects and set up preconditions
- Configure test data and mock dependencies
- Set initial state for the test scenario

#### When (Execution)
- Call the method or function being tested
- Trigger the behavior you want to verify
- Keep this section focused and minimal

#### Then (Verification)
- Use `#expect()` to verify expected outcomes
- Check that side effects occurred as expected
- Verify state changes and return values

### Assertions

Use `#expect()` for assertions:
```swift
#expect(condition, "Descriptive message about what should be true")
#expect(value == expectedValue, "Value should match expected result")
#expect(object.property != nil, "Property should be initialized")
```

### Async Tests

For asynchronous operations:
```swift
@Test func testAsyncOperation() async throws {
    // Given
    let viewModel = CalendarViewModel()

    // When
    await viewModel.loadData()

    // Then
    #expect(viewModel.isLoaded)
}
```

## Test Execution

### Running Tests in Xcode

#### Run All Tests
- Product → Test (⌘U)
- Runs all unit tests and UI tests

#### Run Specific Test Class
- Click the test diamond next to the class name
- Or use the Test Navigator (⌘6)

#### Run Individual Test Method
- Click the test diamond next to the method name
- Useful for debugging specific test failures

### Command Line Execution

#### Run All Tests
```bash
xcodebuild test -scheme "Calendar Play" -destination "platform=macOS"
```

#### Run Specific Tests
```bash
xcodebuild test -scheme "Calendar Play" -destination "platform=macOS" -only-testing:Simple_CalendarTests/testNavigateDateByWeekBackward
```

#### Run with Code Coverage
```bash
xcodebuild test -scheme "Calendar Play" -destination "platform=macOS" -enableCodeCoverage YES
```

### Continuous Integration

Tests should be run as part of your development workflow:
- Run tests before committing changes
- Run tests in CI/CD pipelines
- Ensure all tests pass before merging pull requests

## Best Practices

### Test Isolation
- Each test should be independent and not rely on other tests
- Tests should not share state between executions
- Use fresh instances of objects for each test

### Test Readability
- Use descriptive test names that explain the behavior being tested
- Include comments explaining complex setup or assertions
- Keep tests focused on a single behavior or scenario

### Test Maintainability
- Avoid testing implementation details; test behavior and contracts
- Update tests when refactoring code (not just when adding features)
- Remove obsolete tests when code is removed

### Test Coverage
- Aim for comprehensive coverage of critical paths
- Focus on testing edge cases and error conditions
- Don't aim for 100% coverage at the expense of test quality

### Performance
- Keep tests fast; avoid unnecessary setup or long-running operations
- Use appropriate timeouts for async operations
- Consider test data size and complexity

## Common Patterns

### Testing Date/Time Logic
```swift
let calendar = Calendar(identifier: .gregorian)
let testDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 8))!
let expectedDate = calendar.date(from: DateComponents(year: 2025, month: 12, day: 1))!

// Test date calculations
#expect(calendar.isDate(resultDate, inSameDayAs: expectedDate))
```

### Testing View Model State Changes
```swift
let viewModel = CalendarViewModel()
viewModel.viewMode = .threeDays  // Ensure consistent test conditions

// Perform action
viewModel.navigateDate(by: .week, direction: .backward)

// Verify state
#expect(viewModel.currentDate == expectedDate)
```

### Testing Error Conditions
```swift
@Test func testInvalidInput() async throws {
    let viewModel = CalendarViewModel()

    // When - attempt invalid operation
    viewModel.selectedDate = nil
    viewModel.moveUpOneWeek()

    // Then - should handle gracefully
    #expect(viewModel.selectedDate == nil)  // No crash, maintains nil state
}
```

## Troubleshooting

### Common Issues

#### "Cannot find 'Type' in scope"
- Ensure required imports are present (`import Foundation`, `@testable import Simple_Calendar`)

#### Tests failing due to initialization
- CalendarViewModel may have initialization logic that affects test state
- Set explicit values for viewModel properties in test setup

#### Async test timeouts
- Ensure async operations complete within reasonable time
- Use appropriate expectations for async behavior

#### Date/timezone issues
- Use Calendar(identifier: .gregorian) for consistent date calculations
- Be aware of timezone differences in date comparisons

### Debugging Tests

#### Print Debugging
```swift
print("Debug: currentDate = \(viewModel.currentDate)")
print("Debug: selectedDate = \(viewModel.selectedDate)")
```

#### Xcode Debugging
- Set breakpoints in test methods
- Use the debugger to inspect object state
- Step through test execution

#### Test Failure Analysis
- Read failure messages carefully
- Check expected vs actual values
- Verify test setup matches the scenario being tested

### Getting Help

If you encounter issues with tests:
1. Check this documentation for common patterns
2. Review existing tests for similar scenarios
3. Consult team members for complex testing scenarios
4. Consider simplifying the test or refactoring the code under test

## Maintenance

### When to Update Tests
- When adding new features or functionality
- When refactoring existing code
- When fixing bugs (add regression tests)
- When changing public APIs or behavior

### Test Code Quality
- Keep test code clean and well-organized
- Remove duplicate test code through helper functions
- Document complex test scenarios
- Review tests during code reviews

### Continuous Improvement
- Regularly review test coverage and effectiveness
- Update documentation as testing practices evolve
- Share knowledge about effective testing techniques
- Consider adding integration tests for complex workflows


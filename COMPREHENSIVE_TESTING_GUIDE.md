# 🧪 Comprehensive Testing Guide
## Following TDD & BDD Best Practices

**Created**: November 29, 2025  
**Project**: Coin Circle - Group Savings Mobile Application  
**Testing Framework**: Flutter Test, Mockito, Integration Test

---

## 📋 TABLE OF CONTENTS

1. [Testing Strategy](#testing-strategy)
2. [Unit Testing](#unit-testing)
3. [Widget Testing](#widget-testing)
4. [Integration Testing](#integration-testing)
5. [Test Coverage](#test-coverage)
6. [Best Practices](#best-practices)

---

## 🎯 TESTING STRATEGY

### Testing Pyramid

```
           /\
          /  \
         / E2E \         10% - End-to-End Tests
        /______\
       /        \
      / Integration\     30% - Integration Tests
     /____________\
    /              \
   /  Unit Tests    \   60% - Unit Tests
  /__________________\
```

### Test Coverage Goals

- **Unit Tests**: 80% minimum coverage
- **Widget Tests**: All critical UI components
- **Integration Tests**: All user flows
- **E2E Tests**: Critical business scenarios

---

## 🔬 UNIT TESTING

### 1. Service Layer Tests

#### Example: WalletService Test

```dart
// test/core/services/wallet_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:coin_circle/core/services/wallet_service.dart';
import 'package:coin_circle/core/exceptions/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, SupabaseQueryBuilder])
import 'wallet_service_test.mocks.dart';

void main() {
  group('WalletService', () {
    late WalletService walletService;
    late MockSupabaseClient mockClient;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      walletService = WalletService(client: mockClient);
    });
    
    tearDown(() {
      // Clean up after each test
    });
    
    group('getWallet', () {
      test('should return wallet when successful', () async {
        // Arrange
        final userId = 'test-user-123';
        final mockData = {
          'id': 'wallet-123',
          'user_id': userId,
          'available_balance': 1000.0,
          'locked_balance': 500.0,
          'total_winnings': 2000.0,
        };
        
        when(mockClient.from('wallets'))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockClient.from('wallets').select())
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockClient.from('wallets').select().eq('user_id', userId))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockClient.from('wallets').select().eq('user_id', userId).single())
            .thenAnswer((_) async => mockData);
        
        // Act
        final result = await walletService.getWallet(userId);
        
        // Assert
        expect(result.id, equals('wallet-123'));
        expect(result.availableBalance, equals(1000.0));
        expect(result.lockedBalance, equals(500.0));
        expect(result.totalWinnings, equals(2000.0));
        
        verify(mockClient.from('wallets').select().eq('user_id', userId).single())
            .called(1);
      });
      
      test('should throw WalletNotFoundException when wallet not found', () async {
        // Arrange
        final userId = 'non-existent-user';
        
        when(mockClient.from('wallets').select().eq('user_id', userId).single())
            .thenThrow(PostgrestException(message: 'Not found', code: '404'));
        
        // Act & Assert
        expect(
          () => walletService.getWallet(userId),
          throwsA(isA<WalletNotFoundException>()),
        );
      });
      
      test('should throw WalletException on database error', () async {
        // Arrange
        final userId = 'test-user-123';
        
        when(mockClient.from('wallets').select().eq('user_id', userId).single())
            .thenThrow(Exception('Database connection failed'));
        
        // Act & Assert
        expect(
          () => walletService.getWallet(userId),
          throwsA(isA<WalletException>()),
        );
      });
    });
    
    group('deposit', () {
      test('should successfully deposit money', () async {
        // Arrange
        final userId = 'test-user-123';
        final amount = 1000.0;
        
        when(mockClient.from('wallets').update(any).eq('user_id', userId))
            .thenAnswer((_) async => []);
        
        // Act
        await walletService.deposit(userId, amount);
        
        // Assert
        verify(mockClient.from('wallets').update(any).eq('user_id', userId))
            .called(1);
      });
      
      test('should throw ValidationException for invalid amount', () async {
        // Arrange
        final userId = 'test-user-123';
        final invalidAmount = -100.0;
        
        // Act & Assert
        expect(
          () => walletService.deposit(userId, invalidAmount),
          throwsA(isA<ValidationException>()),
        );
      });
    });
    
    group('withdraw', () {
      test('should successfully withdraw money', () async {
        // Arrange
        final userId = 'test-user-123';
        final amount = 500.0;
        final currentBalance = 1000.0;
        
        when(mockClient.from('wallets').select().eq('user_id', userId).single())
            .thenAnswer((_) async => {
              'available_balance': currentBalance,
            });
        
        when(mockClient.from('wallets').update(any).eq('user_id', userId))
            .thenAnswer((_) async => []);
        
        // Act
        await walletService.withdraw(userId, amount);
        
        // Assert
        verify(mockClient.from('wallets').update(any).eq('user_id', userId))
            .called(1);
      });
      
      test('should throw InsufficientBalanceException when balance is low', () async {
        // Arrange
        final userId = 'test-user-123';
        final amount = 1500.0;
        final currentBalance = 1000.0;
        
        when(mockClient.from('wallets').select().eq('user_id', userId).single())
            .thenAnswer((_) async => {
              'available_balance': currentBalance,
            });
        
        // Act & Assert
        expect(
          () => walletService.withdraw(userId, amount),
          throwsA(isA<InsufficientBalanceException>()),
        );
      });
    });
  });
}
```

### 2. Validator Tests

```dart
// test/core/validators/input_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coin_circle/core/validators/input_validator.dart';

void main() {
  group('InputValidator', () {
    group('validateAmount', () {
      test('should return null for valid amount', () {
        expect(InputValidator.validateAmount('100'), isNull);
        expect(InputValidator.validateAmount('1000.50'), isNull);
        expect(InputValidator.validateAmount('0.01'), isNull);
      });
      
      test('should return error for empty value', () {
        expect(InputValidator.validateAmount(''), isNotNull);
        expect(InputValidator.validateAmount(null), isNotNull);
      });
      
      test('should return error for invalid format', () {
        expect(InputValidator.validateAmount('abc'), isNotNull);
        expect(InputValidator.validateAmount('10.5.5'), isNotNull);
      });
      
      test('should return error for zero or negative', () {
        expect(InputValidator.validateAmount('0'), isNotNull);
        expect(InputValidator.validateAmount('-100'), isNotNull);
      });
      
      test('should return error for too many decimal places', () {
        expect(InputValidator.validateAmount('100.123'), isNotNull);
      });
      
      test('should respect min and max limits', () {
        expect(
          InputValidator.validateAmount('50', minAmount: 100),
          isNotNull,
        );
        expect(
          InputValidator.validateAmount('2000000', maxAmount: 1000000),
          isNotNull,
        );
      });
    });
    
    group('validateEmail', () {
      test('should return null for valid email', () {
        expect(InputValidator.validateEmail('test@example.com'), isNull);
        expect(InputValidator.validateEmail('user.name@domain.co.in'), isNull);
      });
      
      test('should return error for invalid email', () {
        expect(InputValidator.validateEmail('invalid'), isNotNull);
        expect(InputValidator.validateEmail('test@'), isNotNull);
        expect(InputValidator.validateEmail('@example.com'), isNotNull);
      });
    });
    
    group('validatePhoneNumber', () {
      test('should return null for valid Indian phone number', () {
        expect(InputValidator.validatePhoneNumber('9876543210'), isNull);
        expect(InputValidator.validatePhoneNumber('919876543210'), isNull);
        expect(InputValidator.validatePhoneNumber('+919876543210'), isNull);
      });
      
      test('should return error for invalid phone number', () {
        expect(InputValidator.validatePhoneNumber('123456'), isNotNull);
        expect(InputValidator.validatePhoneNumber('5876543210'), isNotNull);
      });
    });
    
    group('validatePIN', () {
      test('should return null for valid PIN', () {
        expect(InputValidator.validatePIN('1357'), isNull);
        expect(InputValidator.validatePIN('9876'), isNull);
      });
      
      test('should return error for sequential PIN', () {
        expect(InputValidator.validatePIN('1234'), isNotNull);
        expect(InputValidator.validatePIN('4321'), isNotNull);
      });
      
      test('should return error for repeated digits', () {
        expect(InputValidator.validatePIN('1111'), isNotNull);
        expect(InputValidator.validatePIN('0000'), isNotNull);
      });
      
      test('should return error for invalid length', () {
        expect(InputValidator.validatePIN('123'), isNotNull);
        expect(InputValidator.validatePIN('12345'), isNotNull);
      });
    });
  });
}
```

### 3. Utility Tests

```dart
// test/core/utils/retry_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:coin_circle/core/utils/retry_helper.dart';

void main() {
  group('RetryHelper', () {
    test('should succeed on first attempt', () async {
      var attempts = 0;
      
      final result = await RetryHelper.retry(
        operation: () async {
          attempts++;
          return 'success';
        },
        maxAttempts: 3,
      );
      
      expect(result, equals('success'));
      expect(attempts, equals(1));
    });
    
    test('should retry on failure and eventually succeed', () async {
      var attempts = 0;
      
      final result = await RetryHelper.retry(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('Temporary failure');
          }
          return 'success';
        },
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      
      expect(result, equals('success'));
      expect(attempts, equals(3));
    });
    
    test('should throw error after max attempts', () async {
      var attempts = 0;
      
      expect(
        () => RetryHelper.retry(
          operation: () async {
            attempts++;
            throw Exception('Persistent failure');
          },
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
        throwsException,
      );
      
      expect(attempts, equals(3));
    });
    
    test('should respect retryIf predicate', () async {
      var attempts = 0;
      
      expect(
        () => RetryHelper.retry(
          operation: () async {
            attempts++;
            throw FormatException('Invalid format');
          },
          maxAttempts: 3,
          retryIf: (error) => error is! FormatException,
        ),
        throwsA(isA<FormatException>()),
      );
      
      expect(attempts, equals(1)); // Should not retry
    });
  });
}
```

---

## 🎨 WIDGET TESTING

### 1. Screen Widget Tests

```dart
// test/features/wallet/presentation/screens/wallet_dashboard_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:coin_circle/features/wallet/presentation/screens/wallet_dashboard_screen.dart';
import 'package:coin_circle/core/services/wallet_service.dart';

@GenerateMocks([WalletService])
import 'wallet_dashboard_screen_test.mocks.dart';

void main() {
  group('WalletDashboardScreen', () {
    late MockWalletService mockWalletService;
    
    setUp(() {
      mockWalletService = MockWalletService();
    });
    
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      // Arrange
      when(mockWalletService.getWallet(any))
          .thenAnswer((_) async => Future.delayed(Duration(seconds: 1)));
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: WalletDashboardScreen(),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('should display wallet balance when loaded', (WidgetTester tester) async {
      // Arrange
      final mockWallet = Wallet(
        id: 'wallet-123',
        userId: 'user-123',
        availableBalance: 1250.75,
        lockedBalance: 500.0,
        totalWinnings: 2000.0,
      );
      
      when(mockWalletService.getWallet(any))
          .thenAnswer((_) async => mockWallet);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: WalletDashboardScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('₹1,250.75'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
    
    testWidgets('should display error message on failure', (WidgetTester tester) async {
      // Arrange
      when(mockWalletService.getWallet(any))
          .thenThrow(WalletException('Failed to load wallet'));
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: WalletDashboardScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Failed to load wallet'), findsOneWidget);
    });
    
    testWidgets('should refresh data on pull-to-refresh', (WidgetTester tester) async {
      // Arrange
      final mockWallet = Wallet(
        id: 'wallet-123',
        userId: 'user-123',
        availableBalance: 1000.0,
      );
      
      when(mockWalletService.getWallet(any))
          .thenAnswer((_) async => mockWallet);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: WalletDashboardScreen(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Perform pull-to-refresh
      await tester.drag(
        find.byType(RefreshIndicator),
        Offset(0, 300),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      verify(mockWalletService.getWallet(any)).called(2); // Initial + refresh
    });
    
    testWidgets('should navigate to AddMoneyScreen on button tap', (WidgetTester tester) async {
      // Arrange
      final mockWallet = Wallet(
        id: 'wallet-123',
        userId: 'user-123',
        availableBalance: 1000.0,
      );
      
      when(mockWalletService.getWallet(any))
          .thenAnswer((_) async => mockWallet);
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: WalletDashboardScreen(),
          routes: {
            '/add-money': (context) => Scaffold(body: Text('Add Money Screen')),
          },
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Tap Add Money button
      await tester.tap(find.text('Add Money'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Add Money Screen'), findsOneWidget);
    });
  });
}
```

### 2. Custom Widget Tests

```dart
// test/shared/widgets/balance_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coin_circle/shared/widgets/balance_card.dart';

void main() {
  group('BalanceCard', () {
    testWidgets('should display title and amount', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              title: 'Available Balance',
              amount: 1250.75,
              icon: Icons.account_balance_wallet,
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Available Balance'), findsOneWidget);
      expect(find.text('₹1,250.75'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });
    
    testWidgets('should format large amounts correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              title: 'Total Winnings',
              amount: 1234567.89,
              icon: Icons.emoji_events,
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('₹12,34,567.89'), findsOneWidget);
    });
    
    testWidgets('should apply custom color', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceCard(
              title: 'Locked Balance',
              amount: 500.0,
              icon: Icons.lock,
              color: Colors.orange,
            ),
          ),
        ),
      );
      
      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BalanceCard),
          matching: find.byType(Container).first,
        ),
      );
      
      expect(
        (container.decoration as BoxDecoration).color,
        equals(Colors.orange),
      );
    });
  });
}
```

---

## 🔗 INTEGRATION TESTING

### 1. User Flow Tests

```dart
// integration_test/wallet_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:coin_circle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Wallet Flow Integration Tests', () {
    testWidgets('Complete deposit flow', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      
      // Login (assuming already logged in for this test)
      // Navigate to wallet
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      
      // Verify wallet screen loaded
      expect(find.text('Available Balance'), findsOneWidget);
      
      // Tap Add Money
      await tester.tap(find.text('Add Money'));
      await tester.pumpAndSettle();
      
      // Enter amount
      await tester.enterText(
        find.byType(TextField).first,
        '1000',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      
      // Verify bank details shown
      expect(find.text('UPI ID:'), findsOneWidget);
      expect(find.text('Account Number:'), findsOneWidget);
      
      // Enter transaction reference
      await tester.tap(find.text('I have made the payment'));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byType(TextField).last,
        'UTR123456789',
      );
      
      // Submit deposit request
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      
      // Verify success message
      expect(find.text('Deposit request submitted'), findsOneWidget);
    });
    
    testWidgets('View transaction history', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to wallet
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      
      // Scroll to transaction history
      await tester.scrollUntilVisible(
        find.text('Transaction History'),
        500.0,
      );
      
      // Verify transactions are displayed
      expect(find.byType(ListTile), findsWidgets);
      
      // Tap on a transaction
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      
      // Verify transaction details shown
      expect(find.text('Transaction Details'), findsOneWidget);
    });
  });
  
  group('Pool Flow Integration Tests', () {
    testWidgets('Create and join pool flow', (WidgetTester tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to pools
      await tester.tap(find.text('Pools'));
      await tester.pumpAndSettle();
      
      // Tap Create Pool
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Fill pool details
      await tester.enterText(
        find.widgetWithText(TextField, 'Pool Name'),
        'Test Pool',
      );
      
      await tester.enterText(
        find.widgetWithText(TextField, 'Contribution Amount'),
        '1000',
      );
      
      await tester.enterText(
        find.widgetWithText(TextField, 'Number of Members'),
        '10',
      );
      
      // Select pool type
      await tester.tap(find.text('Fixed Order'));
      await tester.pumpAndSettle();
      
      // Create pool
      await tester.tap(find.text('Create Pool'));
      await tester.pumpAndSettle();
      
      // Verify pool created
      expect(find.text('Pool created successfully'), findsOneWidget);
      expect(find.text('Test Pool'), findsOneWidget);
    });
  });
}
```

---

## 📊 TEST COVERAGE

### Running Tests with Coverage

```powershell
# Run all tests with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
start coverage/html/index.html
```

### Coverage Configuration

```yaml
# coverage_options.yaml
coverage:
  exclude:
    - '**/*.g.dart'
    - '**/*.freezed.dart'
    - '**/generated/**'
    - '**/l10n/**'
    - '**/test/**'
  
  minimum_coverage: 80
  
  check_coverage:
    - lib/core/services/
    - lib/core/validators/
    - lib/core/utils/
```

---

## ✅ BEST PRACTICES

### 1. Test Organization

```
test/
├── core/
│   ├── services/
│   │   ├── wallet_service_test.dart
│   │   ├── pool_service_test.dart
│   │   └── admin_service_test.dart
│   ├── validators/
│   │   └── input_validator_test.dart
│   └── utils/
│       ├── retry_helper_test.dart
│       └── circuit_breaker_test.dart
├── features/
│   ├── wallet/
│   │   └── presentation/
│   │       └── screens/
│   │           └── wallet_dashboard_screen_test.dart
│   └── pools/
└── shared/
    └── widgets/
        └── balance_card_test.dart
```

### 2. Test Naming Conventions

```dart
// ✅ GOOD: Descriptive test names
test('should return wallet when user exists', () {});
test('should throw WalletNotFoundException when user not found', () {});
test('should retry 3 times before throwing error', () {});

// ❌ BAD: Vague test names
test('test wallet', () {});
test('error case', () {});
```

### 3. AAA Pattern (Arrange-Act-Assert)

```dart
test('should deposit money successfully', () async {
  // Arrange - Set up test data and mocks
  final userId = 'test-user-123';
  final amount = 1000.0;
  when(mockService.deposit(userId, amount))
      .thenAnswer((_) async => true);
  
  // Act - Execute the operation
  final result = await walletService.deposit(userId, amount);
  
  // Assert - Verify the results
  expect(result, isTrue);
  verify(mockService.deposit(userId, amount)).called(1);
});
```

### 4. Test Data Builders

```dart
// test/helpers/test_data_builders.dart
class WalletBuilder {
  String _id = 'wallet-123';
  String _userId = 'user-123';
  double _availableBalance = 1000.0;
  double _lockedBalance = 0.0;
  double _totalWinnings = 0.0;
  
  WalletBuilder withId(String id) {
    _id = id;
    return this;
  }
  
  WalletBuilder withAvailableBalance(double balance) {
    _availableBalance = balance;
    return this;
  }
  
  Wallet build() {
    return Wallet(
      id: _id,
      userId: _userId,
      availableBalance: _availableBalance,
      lockedBalance: _lockedBalance,
      totalWinnings: _totalWinnings,
    );
  }
}

// Usage in tests
final wallet = WalletBuilder()
    .withId('custom-id')
    .withAvailableBalance(5000.0)
    .build();
```

### 5. Golden Tests for UI

```dart
// test/features/wallet/presentation/screens/wallet_dashboard_golden_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('WalletDashboardScreen golden test', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [
        Device.phone,
        Device.iphone11,
        Device.tabletPortrait,
      ])
      ..addScenario(
        widget: WalletDashboardScreen(),
        name: 'default state',
      );
    
    await tester.pumpDeviceBuilder(builder);
    
    await screenMatchesGolden(tester, 'wallet_dashboard_screen');
  });
}
```

---

## 🚀 RUNNING TESTS

### Command Line

```powershell
# Run all tests
flutter test

# Run specific test file
flutter test test/core/services/wallet_service_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run tests in watch mode (requires package)
flutter test --watch
```

### VS Code Configuration

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Test",
      "type": "dart",
      "request": "launch",
      "program": "test/",
      "args": ["--coverage"]
    }
  ]
}
```

---

## 📝 CONTINUOUS INTEGRATION

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Run Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Check coverage
        run: |
          dart pub global activate coverage
          dart pub global run coverage:format_coverage \
            --lcov \
            --in=coverage \
            --out=coverage/lcov.info \
            --packages=.packages \
            --report-on=lib
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          fail_ci_if_error: true
```

---

**Document Version**: 1.0  
**Last Updated**: November 29, 2025  
**Next Review**: December 15, 2025

// Test Configuration System
// Manages test environment settings and engine selection

enum TestDatabaseEngine {
  sqlite,  // Mobile SQLite
  drift,   // Web Drift
  both     // Run both engines
}

class TestConfig {
  static TestDatabaseEngine currentEngine = TestDatabaseEngine.both;
  static bool verboseLogging = false;

  /// Force tests to run only against SQLite
  static void useOnlySqflite() {
    currentEngine = TestDatabaseEngine.sqlite;
    _log('Test configuration: SQLite engine only');
  }

  /// Force tests to run only against Drift
  static void useOnlyDrift() {
    currentEngine = TestDatabaseEngine.drift;
    _log('Test configuration: Drift engine only');
  }

  /// Run tests against both engines (default)
  static void useBothEngines() {
    currentEngine = TestDatabaseEngine.both;
    _log('Test configuration: Both engines');
  }

  /// Enable verbose logging
  static void enableVerboseLogging() {
    verboseLogging = true;
    _log('Verbose logging enabled');
  }

  /// Check if current engine should run tests
  static bool shouldRunSqfliteTests() {
    return currentEngine == TestDatabaseEngine.sqlite ||
           currentEngine == TestDatabaseEngine.both;
  }

  /// Check if current engine should run tests
  static bool shouldRunDriftTests() {
    return currentEngine == TestDatabaseEngine.drift ||
           currentEngine == TestDatabaseEngine.both;
  }

  static void _log(String message) {
    if (verboseLogging) {
      print('[TestConfig] $message');
    }
  }
}

/// Test environment setup helper
class TestEnvironment {
  static Future<void> setup() async {
    // Common test setup goes here
    if (TestConfig.verboseLogging) {
      print('Setting up test environment...');
    }
  }

  static Future<void> cleanup() async {
    // Common test cleanup goes here
    if (TestConfig.verboseLogging) {
      print('Cleaning up test environment...');
    }
  }
}
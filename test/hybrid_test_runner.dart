// Repository test runner. After the sqflite-removal in issue #112, "hybrid"
// is a vestigial name — there is now a single backend (drift). Kept under
// the original filename / function name to avoid churn in callers.

import 'package:flutter_test/flutter_test.dart';
import 'drift_test_base.dart';

export 'drift_test_base.dart';

void runHybridTests(
    String testGroupName, void Function(DriftTestBase) testFunction) {
  group(testGroupName, () {
    final base = DriftTestBase();

    setUp(() async {
      await base.setUp();
    });

    tearDown(() async {
      await base.tearDown();
    });

    testFunction(base);
  });
}

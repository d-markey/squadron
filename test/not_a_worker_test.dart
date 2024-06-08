@TestOn('vm || browser')
library;

import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'worker_services/not_a_worker_service.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

void execute(TestContext testContext) {
  testContext.run(() {
    test("- Not a worker", () async {
      final worker = NotAWorkerService(testContext);

      var started = false, expired = false;

      await Future.any([
        worker.start().then((_) => started = true),
        Future.delayed(Duration(seconds: 5)).then((_) => expired = true),
      ]);

      expect(started, isFalse);
      expect(expired, isTrue);
    });
  });
}

import 'dart:async';

import '../classes/test_context.dart';
import '../classes/test_platform.dart';
import 'tests_wasm.dart' if (dart.library.html) 'tests_js.dart';

String getTestId(String label) => '\$${label.replaceAll(' ', '-')}';

Iterable<String> get testGroups => TestContext.rootGroups;

Future<TestContext?> run(
    Iterable<String> testLabels, TestPlatform platform) async {
  if (testLabels.isNotEmpty) {
    final testContext = await TestContext.init('/', platform);

    for (var testLabel in testLabels) {
      testContext.onlyTests.add(
        RegExp('${RegExp.escape(testLabel)}.*', caseSensitive: false),
      );
    }

    print(
        'Selected tests: ${testContext.onlyTests.map((r) => r.display()).join(', ')}');
    print('Running on platform ${testContext.clientPlatformName}');

    for (var executor in executors.entries) {
      print('Run from script ${executor.value.script}');
      executor.value.runner(testContext);
      reportStatus('${testContext.pending} tests pending...');
    }

    Timer.periodic(Duration(milliseconds: 100), (t) {
      if (testContext.pending == 0) {
        t.cancel();
      } else {
        reportStatus('${testContext.pending} tests pending...');
      }
    });

    testContext.done
        .then((canceled) => reportStatus(canceled ? 'Cancelled' : 'Done'));

    return testContext;
  } else {
    return null;
  }
}

extension _DisplayExt on Pattern {
  String display() => (this is RegExp) ? (this as RegExp).pattern : toString();
}

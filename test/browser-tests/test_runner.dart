import '../classes/test_context.dart';
import '../classes/test_platform.dart';
import 'tests_js.dart' if (dart.library.js_interop) 'tests_wasm.dart';

Iterable<String> getExecutorLabels() => executors.keys;

String getTestId(String label) => '\$${label.replaceAll(' ', '-')}';

Future<void> run(Iterable<String> testLabels, TestPlatform platform) async {
  final selectedExecutors = <MapEntry<String, void Function(TestContext)>>[];

  for (var testLabel in testLabels) {
    final executor = executors.entries
        .where((e) => testLabel == getTestId(e.key))
        .firstOrNull;
    if (executor == null) {
      print('No executor found for test "$testLabel"');
    } else {
      selectedExecutors.add(executor);
    }
  }

  if (selectedExecutors.isNotEmpty) {
    final testContext = await TestContext.init('/', platform);

    print('Selected tests: ${selectedExecutors.map((e) => e.key).join(',')}');
    print('Running on platform ${testContext.clientPlatformName}');

    for (var executor in selectedExecutors) {
      try {
        executor.value(testContext);
      } catch (ex, st) {
        print('Test "${executor.key}" failed with $ex');
        print(st);
      }
    }
  }
}

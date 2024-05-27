@JS()

import 'dart:html';

import 'package:js/js.dart';

import '../classes/test_context.dart';
import '../classes/test_platform.dart';
import 'html_logger.dart';
import 'tests.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(dynamic message);

void main() async {
  final htmlLogger = HtmlLogger(querySelector('#output') as DivElement);

  dartPrint = allowInterop((dynamic message) {
    htmlLogger.print(message?.toString() ?? '(null)');
  });

  window.onMessage.listen((m) => print('(*) ${m.data}'));

  final selectedExecutors = <MapEntry<String, void Function(TestContext)>>[];

  final uri = Uri.parse(window.location.href);
  for (var test in uri.queryParameters.keys) {
    final executor =
        executors.entries.where((e) => test == getTestId(e.key)).firstOrNull;
    if (executor == null) {
      print('No executor found for test id: $test');
    } else {
      selectedExecutors.add(executor);
    }
  }

  if (selectedExecutors.isNotEmpty) {
    print('Selected tests: ${selectedExecutors.map((e) => e.key).join(',')}');
    final testContext = await TestContext.init('/', TestPlatform.js);

    for (var executor in selectedExecutors) {
      executor.value(testContext);
    }
  }
}

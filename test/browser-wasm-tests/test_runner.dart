import 'dart:js_interop';

import 'package:web/web.dart';

import '../classes/test_context.dart';
import 'html_logger.dart';
import 'tests.dart';

@JS()
external JSFunction? get dartPrint;

@JS()
external set dartPrint(JSFunction? value);

void main(dynamic args) async {
  final htmlLogger =
      HtmlLogger(document.querySelector('#output') as HTMLDivElement);

  dartPrint = (JSAny? message) {
    htmlLogger.print('${message?.dartify() ?? '(null)'}');
  }.toJS;

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
    final testContext = await TestContext.init('/');

    for (var executor in selectedExecutors) {
      print('executor.value = ${executor.value}');
      executor.value(testContext);
    }
  }

  print('Test context platform = ${TestContext.platform}');
}

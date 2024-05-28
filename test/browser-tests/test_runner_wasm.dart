// tests_wasm.dart forces 'dart:js_interop'

import 'dart:js_interop';

import 'package:web/web.dart';

import '../classes/test_context.dart';
import '../classes/test_platform.dart';
import 'html_logger_wasm.dart';
import 'tests_wasm.dart';

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

  print('Imported platform = $importedPlatform');

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
    final testContext = await TestContext.init('/', TestPlatform.wasm);

    for (var executor in selectedExecutors) {
      executor.value(testContext);
    }
  }
}

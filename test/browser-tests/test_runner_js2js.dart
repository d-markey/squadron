// tests_js.dart forces 'dart:html'

import 'dart:html';

import 'package:js/js.dart';

import '../classes/test_context.dart';
import '../classes/test_platform.dart';
import 'html_logger_js.dart';
import 'test_runner.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(dynamic printFn);

void main() async {
  final htmlLogger = HtmlLogger(querySelector('#output') as DivElement);

  dartPrint = allowInterop((dynamic message) {
    htmlLogger.print(message?.toString() ?? '(null)');
  });

  TestContext? context;

  window.onMessage.listen((m) {
    if (m.data == TestContext.cancelled) {
      context?.cancel();
    } else {
      print('(*) ${m.data}');
    }
  });

  context = await run(
    Uri.parse(window.location.href).queryParameters.keys,
    TestPlatform.js,
  );
}

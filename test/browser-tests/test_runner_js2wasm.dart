// tests_js.dart forces 'dart:html'

import 'dart:html';

import 'package:js/js.dart';

import '../classes/test_platform.dart';
import 'html_logger_js.dart';
import 'test_runner.dart';

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

  run(
    Uri.parse(window.location.href).queryParameters.keys,
    TestPlatform.wasm,
  );
}

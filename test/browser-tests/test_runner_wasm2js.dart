// tests_wasm.dart forces 'dart:js_interop'

import 'dart:js_interop';

import 'package:web/web.dart';

import '../classes/test_platform.dart';
import 'html_logger_wasm.dart';
import 'test_runner.dart';

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

  run(
    Uri.parse(window.location.href).queryParameters.keys,
    TestPlatform.js,
  );
}

// tests_wasm.dart forces 'dart:js_interop'

import 'dart:js_interop';

import 'package:web/web.dart';

import '../classes/test_context.dart';
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

  TestContext? context;

  window.onMessage.listen((m) {
    if (m.data.dartify() == TestContext.cancelled) {
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

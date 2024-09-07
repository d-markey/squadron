// tests_wasm.dart forces 'dart:js_interop'

import 'dart:js_interop';

import 'package:squadron/squadron.dart';
import 'package:web/web.dart';

import '../classes/test_context.dart';
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
      print('(*) cancel tests');
      context?.cancel();
    } else {
      print('(*) ${m.data}');
    }
  });

  print('Client platform type = ${Squadron.platformType.label}');

  context = await runTests(
    Uri.parse(window.location.href).queryParameters.keys,
    SquadronPlatformType.wasm,
  );
}

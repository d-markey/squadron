// tests_js.dart forces 'dart:html'

import 'dart:html';

import 'package:js/js.dart';
import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
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

  TestContext? context;

  window.onMessage.listen((m) {
    if (m.data == TestContext.cancelled) {
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

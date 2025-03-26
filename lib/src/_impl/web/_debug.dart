import 'dart:js_interop';

import 'package:web/web.dart';

import '_platform.dart';

void $log(String message) {
  console.log('[$threadId] $message'.toJS);
}

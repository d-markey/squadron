import 'dart:js_interop';

import 'package:web/web.dart';

void unsendable() {}

dynamic getUnsendable() => unsendable;

void $log(String message) {
  console.log(message.toJS);
}

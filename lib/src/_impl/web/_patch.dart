import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

String? getHome() {
  if (window.isUndefinedOrNull) return null;
  final components = window.location.pathname.split('/');
  return components.take(components.length - 1).join('/');
}

String? getErrorEventMessage(JSObject? obj) {
  if (obj != null && obj.has('message')) {
    return obj['message']?.toString();
  } else {
    return null;
  }
}

Object? getErrorEventError(JSObject? obj) {
  if (obj != null && obj.has('error')) {
    return obj['error'].dartify();
  } else {
    return null;
  }
}

List? getMessageEventData(JSObject? obj) {
  if (obj != null && obj.has('data')) {
    final data = obj['data'].dartify();
    return (data == null) ? null : (data as List);
  } else {
    return null;
  }
}

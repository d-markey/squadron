import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

String? getHome() {
  if (window.isUndefinedOrNull) return null;
  final components = window.location.pathname.split('/');
  return components.take(components.length - 1).join('/');
}

String? _getErrorEventMessage(JSObject? obj) {
  if (obj != null && obj.has('message')) {
    return obj['message'].dartify()?.toString();
  } else {
    return null;
  }
}

Object? _getErrorEventError(JSObject? obj) {
  if (obj != null && obj.has('error')) {
    return obj['error'].dartify();
  } else {
    return null;
  }
}

Object getError(JSObject? obj) =>
    _getErrorEventError(obj) ?? _getErrorEventMessage(obj) ?? 'Unknown error';

List? getMessageEventData(JSObject? obj) {
  if (obj != null && obj.has('data')) {
    return obj['data'].dartify() as List?;
  } else {
    return null;
  }
}

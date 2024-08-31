import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS()
external JSPromise<web.Response> fetch(JSAny resource, [JSAny? options]);

class UriChecker {
  UriChecker._();

  static Future<bool> exists(Uri url) async {
    if (url.isScheme('data')) return true;
    try {
      final res =
          await fetch(url.toString().toJS, {'method': 'HEAD'}.jsify()).toDart;
      return res.ok && (200 <= res.status) && (res.status < 300);
    } catch (_) {
      return false;
    }
  }
}

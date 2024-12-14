import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS()
external JSPromise<web.Response> fetch(JSAny resource, [JSAny? options]);

class UriChecker {
  UriChecker._();

  static final _headers = {'method': 'HEAD'}.jsify();

  static Future<bool> exists(Uri url) async {
    if (url.isScheme('data') || url.isScheme('blob')) return true;
    try {
      final res = await fetch(url.toString().toJS, _headers).toDart;
      return res.ok && (200 <= res.status) && (res.status < 300);
    } catch (_) {
      return false;
    }
  }
}

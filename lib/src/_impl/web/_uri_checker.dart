import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS()
external JSPromise<web.Response> fetch(JSAny resource, [JSAny? options]);

class UriChecker {
  UriChecker._();

  static final _headers = {'method': 'HEAD'}.jsify();

  static Future<bool> exists(Uri url) =>
      (url.isScheme('data') || url.isScheme('blob'))
          ? Future.value(true)
          : fetch(url.toString().toJS, _headers).toDart.then(
                (res) => res.ok && (200 <= res.status) && (res.status < 300),
                onError: (_) => false,
              );
}

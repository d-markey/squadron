import 'dart:js_interop';

import 'package:web/web.dart';

import '_patch.dart';

@JS()
external DedicatedWorkerGlobalScope get self;

Uri mapUrl(String url) {
  if (url.startsWith('~')) {
    final root = getHome();
    if (root != null) {
      url = '$root${url.substring(1)}';
    }
  }
  return Uri.parse(url);
}

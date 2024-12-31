import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart';

String? getHome() {
  if (window.isUndefinedOrNull) return null;
  final components = window.location.pathname.split('/');
  return components.take(components.length - 1).join('/');
}

String? _getErrorEventMessage(JSObject? obj) {
  if (obj != null && obj.has('message')) {
    return $dartify(obj.getProperty('message'.toJS))?.toString();
  } else {
    return null;
  }
}

Object? _getErrorEventError(JSObject? obj) {
  if (obj != null && obj.has('error')) {
    return $dartify(obj.getProperty('error'.toJS));
  } else {
    return null;
  }
}

Object getError(JSObject? obj) =>
    _getErrorEventError(obj) ?? _getErrorEventMessage(obj) ?? 'Unknown error';

List? getMessageEventData(JSObject? obj) {
  if (obj != null && obj.has('data')) {
    return $dartify(obj.getProperty('data'.toJS)) as List?;
  } else {
    return null;
  }
}

@JS('Map')
extension type _$JSMap._(JSObject _) implements JSObject {
  external factory _$JSMap();
  external JSAny get(JSAny? key);
  external void set(JSAny? key, JSAny? value);
  external JSObject keys();
}

@JS('BigInt')
external JSBigInt _$JSBigInt(JSAny? value);

extension on JSBigInt {
  @JS('toString')
  external JSString $toString();
}

extension _$JSIteratorExt on JSObject {
  JSObject? next() => callMethod(_$next);
  bool get done => getProperty(_$done).isTruthy.toDart;
  JSAny? get value => getProperty(_$value);

  static final _$next = 'next'.toJS;
  static final _$done = 'done'.toJS;
  static final _$value = 'value'.toJS;
}

JSAny? _jsify(Object? obj, Map<Object, JSAny> cache) {
  if (obj == null) return null;
  var js = cache[obj];
  if (js != null) return js;
  if (obj is BigInt) {
    final bigint = _$JSBigInt(obj.toString().toJS);
    print('BigInt $obj -> $bigint [${bigint.runtimeType}]');
    return bigint;
  }
  if (obj is Map) {
    final map = _$JSMap();
    cache[obj] = map;
    for (var entry in obj.entries) {
      map.set(_jsify(entry.key, cache), _jsify(entry.value, cache));
    }
    print('_jsify: $map');
    return map;
  }
  if (obj is List && obj is! TypedData) {
    final len = obj.length;
    final list = JSArray();
    cache[obj] = list;
    for (var i = 0; i < len; i++) {
      list.setProperty(i.toJS, _jsify(obj[i], cache));
    }
    return list;
  }
  js = obj.jsify();
  if (js != null && obj is! num && obj is! bool && obj is! String) {
    cache[obj] = js;
  }
  return js;
}

JSAny? $jsify(Object? obj) {
  return _jsify(obj, Map<Object, JSAny>.identity());
  // return obj.jsify();
}

Object? _dartify(JSAny? js, Map<JSAny, Object> cache) {
  if (js.isUndefinedOrNull) return null;
  var obj = cache[js!];
  if (obj != null) return obj;
  if (js.isA<JSBigInt>()) {
    js as JSBigInt;
    final strVal = js.$toString().toDart;
    print('BigInt $js -> $strVal');
    return BigInt.parse(strVal);
  }
  if (js.isA<_$JSMap>()) {
    print('_dartify: $js');
    final map = {};
    cache[js] = map;
    js as _$JSMap;
    final keys = js.keys();
    while (true) {
      final res = keys.next();
      if (res == null || res.done) break;
      final key = res.value;
      final value = js.get(key);
      map[_dartify(key, cache)] = _dartify(value, cache);
    }
    return map;
  }
  if (js.isA<JSArray>()) {
    final list = [];
    cache[js] = list;
    js as JSArray;
    final len = js.getProperty<JSNumber>('length'.toJS).toDartInt;
    for (var i = 0; i < len; i++) {
      final value = js.getProperty(i.toJS);
      list.add(_dartify(value, cache));
    }
    return list;
  }
  obj = js.dartify();
  if (obj != null && obj is! num && obj is! bool && obj is! String) {
    cache[js] = obj;
  }
  return obj;
}

Object? $dartify(JSAny? js) {
  return _dartify(js, Map<JSAny, Object>.identity());
  // return js.dartify();
}

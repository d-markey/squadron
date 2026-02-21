import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../squadron_singleton.dart';
import '../../worker/worker_message.dart';

String? getRootUrl() {
  if (web.window.isUndefinedOrNull) return null;
  final components = web.window.location.pathname.split('/');
  return components.take(components.length - 1).join('/');
}

bool _isTransferable(JSAny js) {
  // see https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects#supported_objects
  if (js.isA<JSArrayBuffer>()) return true;
  if (js.isA<web.MessagePort>()) return true;
  if (js.isA<web.ReadableStream>()) return true;
  if (js.isA<web.WritableStream>()) return true;
  if (js.isA<web.TransformStream>()) return true;
  // if (js.isA<web.WebTransportReceiveStream>()) return true; // not implemented in package web.dart; may be supported via ReadableStream
  // if (js.isA<web.WebTransportSendStream>()) return true; // not implemented in package web.dart; may be supported via WritableStream
  // if (js.isA<web.AudioData>()) return true; // not implemented in package web.dart
  if (js.isA<web.ImageBitmap>()) return true;
  if (js.isA<web.VideoFrame>()) return true;
  if (js.isA<web.OffscreenCanvas>()) return true;
  if (js.isA<web.RTCDataChannel>()) return true;
  if (js.isA<web.MediaSourceHandle>()) return true;
  if (js.isA<web.MIDIAccess>()) return true;
  return false;
}

typedef ToJsFunc = JSAny? Function(Object?);
typedef ToDartFunc = Object? Function(JSAny?);

bool _isJSBaseType(JSAny? js) {
  if (js.isUndefinedOrNull) return true;
  js as JSAny;
  return js.isA<JSNumber>() || js.isA<JSString>() || js.isA<JSBoolean>();
}

void $transferify(JSAny? message, JSArray transfer) {
  if (_isJSBaseType(message)) return;

  // slow path
  message as JSAny;
  final registered = HashSet<JSAny>(equals: (a, b) => $is(a, b));

  late final void Function(JSAny?) squadronTransferify;
  squadronTransferify = (js) {
    if (_isJSBaseType(js)) return;

    // slow path
    js as JSAny;

    // for typed array, transfer the underlying buffer
    if (js.isA<JSTypedArray>()) {
      js = js.$buffer;
      if (registered.add(js)) transfer.$add(js);
      return;
    }

    // nothing to do if already visited
    if (!registered.add(js)) return;

    // array buffer are transfered as is
    if (js.isA<JSArrayBuffer>()) {
      transfer.$add(js);
      return;
    }

    // inspect array contents
    if (js.isA<JSArray>()) {
      js as JSArray;
      final len = js.$length;
      for (var i = 0; i < len; i++) {
        squadronTransferify(js.$at(i));
      }
      return;
    }

    // inspect map contents
    if (js.isA<$JSMap>()) {
      js as $JSMap;
      final keys = js.$entries();
      while (true) {
        final res = keys.$next();
        if (res == null || res.$done) break;
        final entry = res.$value as JSArray; // [key, value]
        squadronTransferify(entry.$at(0));
        squadronTransferify(entry.$at(1));
      }
      return;
    }

    // inspect set contents
    if (js.isA<$JSSet>()) {
      js as $JSSet;
      final values = js.$values();
      while (true) {
        final res = values.$next();
        if (res == null || res.$done) break;
        final value = res.$value;
        squadronTransferify(value);
      }
      return;
    }

    // register other JS objects
    if (_isTransferable(js)) {
      transfer.$add(js);
    }
  };

  squadronTransferify(message);
}

JSAny? _toJSStr(Object? value) => (value as String?)?.toJS;
JSAny? _toJSBool(Object? value) => (value as bool?)?.toJS;
JSAny? _toJSNum(Object? value) => (value as num?)?.toJS;
JSAny? _toJSBigInt(Object? value) =>
    (value == null) ? null : $JSBigInt((value as BigInt).toString().toJS);
JSAny? _toJSDate(Object? value) => (value == null)
    ? null
    : $JSDate.$fromUnixTimestamp((value as DateTime).millisecondsSinceEpoch);

void _noRegistration(JSAny js) {}

JSAny? _getJSValue(Object dart) {
  if (dart is num) return dart.toJS;
  if (dart is String) return dart.toJS;
  if (dart is bool) return dart.toJS;
  // support BigInt & DateTime objects
  if (dart is BigInt) return _toJSBigInt(dart);
  if (dart is DateTime) return _toJSDate(dart);
  return null;
}

JSArray $jsify(WorkerMessage message, JSArray? transfer) {
  final cache = HashMap<Object, JSAny>(equals: Squadron.identical);

  final $registerTransferable = (transfer == null)
      ? _noRegistration
      : ((JSAny js) {
          // for typed array, transfer the underlying buffer
          if (js.isA<JSTypedArray>()) {
            js = js.$buffer;
            if (cache.containsKey(js)) return;
            cache[js] = js;
            transfer.$add(js);
          } else if (_isTransferable(js)) {
            transfer.$add(js);
          }
        });

  late final ToJsFunc squadronJsify;
  squadronJsify = (obj) {
    // fast path
    if (obj == null) return null;
    final js = _getJSValue(obj);
    if (js != null) return js;

    // slow path

    // use cached object if available
    final cached = cache[obj];
    if (cached != null) return cached;

    // process non-TypedData List object recursively
    if (obj is List && obj is! TypedData) {
      ToJsFunc jsifier;
      if (obj is List<String?>) {
        jsifier = _toJSStr;
      } else if (obj is List<bool?>) {
        jsifier = _toJSBool;
      } else if (obj is List<num?>) {
        jsifier = _toJSNum;
      } else if (obj is List<BigInt?>) {
        jsifier = _toJSBigInt;
      } else if (obj is List<DateTime?>) {
        jsifier = _toJSDate;
      } else {
        jsifier = squadronJsify;
      }

      final jsArray = JSArray(), len = obj.length;
      cache[obj] = jsArray;
      for (var i = 0; i < len; i++) {
        jsArray.$add(jsifier(obj[i]));
      }
      return jsArray;
    }

    // process Map object recursively
    if (obj is Map) {
      ToJsFunc kjsifier;
      if (obj is Map<String?, dynamic>) {
        kjsifier = _toJSStr;
      } else if (obj is Map<bool?, dynamic>) {
        kjsifier = _toJSBool;
      } else if (obj is Map<num?, dynamic>) {
        kjsifier = _toJSNum;
      } else if (obj is Map<BigInt?, dynamic>) {
        kjsifier = _toJSBigInt;
      } else if (obj is Map<DateTime?, dynamic>) {
        kjsifier = _toJSDate;
      } else {
        kjsifier = squadronJsify;
      }

      ToJsFunc vjsifier;
      if (obj is Map<dynamic, String?>) {
        vjsifier = _toJSStr;
      } else if (obj is Map<dynamic, bool?>) {
        vjsifier = _toJSBool;
      } else if (obj is Map<dynamic, num?>) {
        vjsifier = _toJSNum;
      } else if (obj is Map<dynamic, BigInt?>) {
        vjsifier = _toJSBigInt;
      } else if (obj is Map<dynamic, DateTime?>) {
        vjsifier = _toJSDate;
      } else {
        vjsifier = squadronJsify;
      }

      final jsMap = $JSMap();
      cache[obj] = jsMap;
      for (var o in obj.entries) {
        jsMap.$set(kjsifier(o.key), vjsifier(o.value));
      }
      return jsMap;
    }

    // process Set object recursively
    if (obj is Set) {
      ToJsFunc jsifier;
      if (obj is Set<String?>) {
        jsifier = _toJSStr;
      } else if (obj is Set<bool?>) {
        jsifier = _toJSBool;
      } else if (obj is Set<num?>) {
        jsifier = _toJSNum;
      } else if (obj is Set<BigInt?>) {
        jsifier = _toJSBigInt;
      } else if (obj is Set<DateTime?>) {
        jsifier = _toJSDate;
      } else {
        jsifier = squadronJsify;
      }

      final jsSet = $JSSet();
      cache[obj] = jsSet;
      for (var o in obj) {
        jsSet.$add(jsifier(o));
      }
      return jsSet;
    }

    // otherwise, delegate to Dart's jsify()
    final res = obj.jsify();

    // cache result and update list of transferable objects
    if (res.isDefinedAndNotNull) {
      res as JSAny;
      cache[obj] = res;
      $registerTransferable(res);
    }

    return res;
  };

  return squadronJsify(message.data) as JSArray;
}

Object? _getDartValue(JSAny js) {
  if (js.isA<JSNumber>()) return (js as JSNumber).dartify();
  if (js.isA<JSString>()) return (js as JSString).toDart;
  if (js.isA<JSBoolean>()) return (js as JSBoolean).toDart;
  // support JS BigInt & Date objects
  if (js.isA<JSBigInt>()) {
    return BigInt.parse((js as JSBigInt).$toString().toDart);
  }
  if (js.isA<$JSDate>()) {
    return DateTime.fromMillisecondsSinceEpoch((js as $JSDate).$getTime());
  }
  return null;
}

Object? $dartify(JSAny? message) {
  // fast path
  if (message.isUndefinedOrNull) return null;
  message as JSAny;
  final dart = _getDartValue(message);
  if (dart != null) return dart;

  // slow path
  final cache = HashMap<JSAny, Object>(equals: Squadron.identical);

  late final ToDartFunc squadronDartify;
  squadronDartify = (js) {
    // fast path
    if (js.isUndefinedOrNull) return null;
    js as JSAny;
    final dart = _getDartValue(js);
    if (dart != null) return dart;

    // slow path

    // use cached object if available
    final cached = cache[js];
    if (cached != null) return cached;

    // process JS Array object recursively
    if (js.isA<JSArray>()) {
      final len = (js as JSArray).$length, dartList = [];
      cache[js] = dartList;
      for (var i = 0; i < len; i++) {
        dartList.add(squadronDartify(js.$at(i)));
      }
      return dartList;
    }

    // process JS Map object recursively
    if (js.isA<$JSMap>()) {
      final keys = (js as $JSMap).$entries(), dartMap = {};
      cache[js] = dartMap;
      while (true) {
        final res = keys.$next();
        if (res == null || res.$done) break;
        final entry = res.$value as JSArray; // [key, value]
        dartMap[squadronDartify(entry.$at(0))] = squadronDartify(entry.$at(1));
      }
      return dartMap;
    }

    // process JS Set object recursively
    if (js.isA<$JSSet>()) {
      final values = (js as $JSSet).$values(), dartSet = <dynamic>{};
      cache[js] = dartSet;
      while (true) {
        final res = values.$next();
        if (res == null || res.$done) break;
        dartSet.add(squadronDartify(res.$value));
      }
      return dartSet;
    }

    // delegate to Dart's dartify()
    final res = js.dartify();

    // cache result
    if (res != null && res is! num && res is! bool && res is! String) {
      cache[js] = res;
    }

    return res;
  };

  return squadronDartify(message);
}

extension $JSEventExt on web.Event? {
  static String? _getErrorEventMessage(web.Event? obj) =>
      $dartify(obj?.getProperty(_$kMessage))?.toString();

  static Object? _getErrorEventError(web.Event? obj) =>
      $dartify(obj?.getProperty(_$kError));

  static Object? _getMessageEventData(web.Event? obj) =>
      $dartify(obj?.getProperty(_$kData));

  Object get $dartError =>
      _getErrorEventError(this) ??
      _getErrorEventMessage(this) ??
      'Unknown error';

  List? get $dartData => _getMessageEventData(this) as List?;
}

@JS('Object.is')
external bool $is(JSAny? a, JSAny? b);

extension $JSArrayExt on JSArray {
  @JS('push')
  external int $add(JSAny? value);
  @JS('at')
  external JSAny? $at(int index);
  @JS('length')
  external int get $length;
}

extension $JSArrayBufferExt on JSArrayBuffer {
  @JS('byteLength')
  external int get $byteLength;
}

final _$JSDateFunction = globalContext['Date'] as JSFunction;

@JS('Date')
extension type $JSDate(JSObject _) implements JSObject {
  factory $JSDate.$fromUnixTimestamp(int millisecondsSinceEpoch) =>
      _$JSDateFunction.callAsConstructor(millisecondsSinceEpoch.toJS);
  @JS('getTime')
  external int $getTime();
}

@JS('BigInt')
external JSBigInt $JSBigInt(JSAny? value);

extension on JSBigInt {
  @JS('toString')
  external JSString $toString();
}

typedef $JSIterator = JSObject;
typedef $JSIteratorResult = JSObject;

@JS('Map')
extension type $JSMap._(JSObject _) implements JSObject {
  external factory $JSMap();
  @JS('set')
  external $JSMap $set(JSAny? key, JSAny? value);
  @JS('entries')
  external $JSIterator $entries();
}

@JS('Set')
extension type $JSSet._(JSObject _) implements JSObject {
  external factory $JSSet();
  @JS('add')
  external $JSSet $add(JSAny? value);
  @JS('values')
  external $JSIterator $values();
}

extension $JSIteratorExt on $JSIterator {
  $JSIteratorResult? $next() => callMethod(_$kNext);
}

extension $JSIteratorResultExt on $JSIteratorResult {
  bool get $done => getProperty(_$kDone).isTruthy.toDart;
  JSAny? get $value => getProperty(_$kValue);
}

extension $JSTypedArrayExt on JSAny {
  @JS('buffer')
  // use after a successful call to `isA<JSTypedArray>()`
  external JSAny get $buffer;
}

// events
final _$kMessage = 'message'.toJS;
final _$kError = 'error'.toJS;
final _$kData = 'data'.toJS;

// iterators & results
final _$kNext = 'next'.toJS;
final _$kDone = 'done'.toJS;
final _$kValue = 'value'.toJS;

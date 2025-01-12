import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String? getRootUrl() {
  if (web.window.isUndefinedOrNull) return null;
  final components = web.window.location.pathname.split('/');
  return components.take(components.length - 1).join('/');
}

bool _isTransferable(JSAny js) {
  // see https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects#supported_objects
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

void _registerTransferable(JSAny js, JSArray transfer) {
  if (js.isA<JSTypedArray>()) {
    final buffer = (js as JSTypedArray).buffer;
    if (buffer.isA<JSArrayBuffer>()) {
      transfer.push(buffer);
    }
  } else if (_isTransferable(js)) {
    transfer.push(js);
  }
}

void $transferify(JSAny? message, JSArray transfer) {
  final registered = HashSet<JSAny>.identity();

  void squadronTransferify(JSAny? obj) {
    if (obj.isUndefinedOrNull) return;
    obj as JSAny;

    // nothing to do if already visited
    if (!registered.add(obj)) return;

    // inspect array contents
    if (obj.isA<JSArray>()) {
      final len = (obj as JSArray).length;
      for (var i = 0; i < len; i++) {
        squadronTransferify(obj.at(i));
      }
      return;
    }

    // inspect map contents
    if (obj.isA<_$JSMap>()) {
      final keys = (obj as _$JSMap).entries();
      while (true) {
        final res = keys.next();
        if (res == null || res.done) break;
        final entry = res.value as JSArray; // [key, value]
        squadronTransferify(entry.at(0));
        squadronTransferify(entry.at(1));
      }
      return;
    }

    // inspect set contents
    if (obj.isA<_$JSSet>()) {
      final values = (obj as _$JSSet).values();
      while (true) {
        final res = values.next();
        if (res == null || res.done) break;
        final value = res.value;
        squadronTransferify(value);
      }
      return;
    }

    // register other JS objects
    _registerTransferable(obj, transfer);
  }

  squadronTransferify(message);
}

JSAny? $jsify(Object? message, JSArray? transfer) {
  final cache = HashMap<Object, JSAny>.identity();

  JSAny? squadronJsify(Object? obj) {
    if (obj == null) return null;

    // use cached object if available
    var cached = cache[obj];
    if (cached != null) return cached;

    // process List object recursively
    if (obj is List && obj is! TypedData) {
      final len = obj.length, jsArray = cache[obj] = JSArray();
      for (var i = 0; i < len; i++) {
        jsArray.push(squadronJsify(obj[i]));
      }
      return jsArray;
    }

    // process Map object recursively
    if (obj is Map) {
      final jsMap = cache[obj] = _$JSMap();
      for (var entry in obj.entries) {
        jsMap.set(
          squadronJsify(entry.key),
          squadronJsify(entry.value),
        );
      }
      return jsMap;
    }

    // process Set object recursively
    if (obj is Set) {
      final jsSet = cache[obj] = _$JSSet();
      for (var value in obj) {
        jsSet.add(squadronJsify(value));
      }
      return jsSet;
    }

    // support BigInt object
    if (obj is BigInt) {
      return _$JSBigInt(obj.toString().toJS);
    }

    // delegate to Dart's jsify()
    final res = obj.jsify();

    // cache result and update list of transferable objects
    if (res.isDefinedAndNotNull) {
      res as JSAny;
      if (obj is! num && obj is! bool && obj is! String) {
        cache[obj] = res;
      }
      if (transfer != null) {
        _registerTransferable(res, transfer);
      }
    }

    return res;
  }

  final jsMessage = squadronJsify(message);

  /////////// >>> using Dart's jsify implementation
  // final jsMessage = message.jsify();
  // if (transfer != null) {
  //   $transferify(jsMessage, transfer);
  // }
  /////////// <<< using Dart's jsify implementation

  return jsMessage;
}

Object? $dartify(JSAny? message) {
  final cache = HashMap<JSAny, Object>.identity();

  Object? squadronDartify(JSAny? js) {
    if (js.isUndefinedOrNull) return null;

    // use cached object if available
    final cached = cache[js!];
    if (cached != null) return cached;

    // process JS Array object recursively
    if (js.isA<JSArray>()) {
      final len = (js as JSArray).length, dartList = cache[js] = [];
      for (var i = 0; i < len; i++) {
        dartList.add(squadronDartify(js.at(i)));
      }
      return dartList;
    }

    // process JS Map object recursively
    if (js.isA<_$JSMap>()) {
      final keys = (js as _$JSMap).entries(), dartMap = cache[js] = {};
      while (true) {
        final res = keys.next();
        if (res == null || res.done) break;
        final entry = res.value as JSArray; // [key, value]
        dartMap[squadronDartify(entry.at(0))] = squadronDartify(entry.at(1));
      }
      return dartMap;
    }

    // process JS Set object recursively
    if (js.isA<_$JSSet>()) {
      final values = (js as _$JSSet).values(),
          dartSet = cache[js] = <dynamic>{};
      while (true) {
        final res = values.next();
        if (res == null || res.done) break;
        dartSet.add(squadronDartify(res.value));
      }
      return dartSet;
    }

    // support JS BigInt object
    if (js.isA<JSBigInt>()) {
      return BigInt.parse((js as JSBigInt).$toString().toDart);
    }

    // delegate to Dart's dartify()
    final res = js.dartify();

    // cache result
    if (res != null && res is! num && res is! bool && res is! String) {
      cache[js] = res;
    }

    return res;
  }

  final dartMessage = squadronDartify(message);

  ///////////// >>> using Dart's dartify implementation
  // final dartMessage = js.dartify();
  ///////////// <<< using Dart's dartify implementation

  return dartMessage;
}

extension $JSEventExt on web.Event? {
  static String? _getErrorEventMessage(web.Event? obj) =>
      $dartify(obj?.getProperty(_$JSProps.message))?.toString();

  static Object? _getErrorEventError(web.Event? obj) =>
      $dartify(obj?.getProperty(_$JSProps.error));

  static Object? _getMessageEventData(web.Event? obj) =>
      $dartify(obj?.getProperty(_$JSProps.data));

  Object get dartError =>
      _getErrorEventError(this) ??
      _getErrorEventMessage(this) ??
      'Unknown error';

  List? get dartData => _getMessageEventData(this) as List?;
}

extension JSArrayExt on JSArray {
  @JS()
  external void push(JSAny? value);
  @JS()
  external JSAny? at(int index);
  @JS()
  external int get length;
}

@JS('BigInt')
external JSBigInt _$JSBigInt(JSAny? value);

extension on JSBigInt {
  @JS('toString')
  external JSString $toString();
}

typedef _$JSIterator = JSObject;
typedef _$JSIteratorResult = JSObject;

@JS('Map')
extension type _$JSMap._(JSObject _) implements JSObject {
  external factory _$JSMap();
  external void set(JSAny? key, JSAny? value);
  external _$JSIterator entries();
}

@JS('Set')
extension type _$JSSet._(JSObject _) implements JSObject {
  external factory _$JSSet();
  external _$JSSet add(JSAny? value);
  external _$JSIterator values();
}

extension _$JSIteratorExt on _$JSIterator {
  _$JSIteratorResult? next() => callMethod(_$JSProps.next);
}

extension _$JSIteratorResultExt on _$JSIteratorResult {
  bool get done => getProperty(_$JSProps.done).isTruthy.toDart;
  JSAny? get value => getProperty(_$JSProps.value);
}

extension _$JSTypedArrayExt on JSTypedArray {
  JSAny? get buffer => getProperty(_$JSProps.buffer);
}

sealed class _$JSProps {
  // events
  static final message = 'message'.toJS;
  static final error = 'error'.toJS;
  static final data = 'data'.toJS;

  // iterators & results
  static final next = 'next'.toJS;
  static final done = 'done'.toJS;
  static final value = 'value'.toJS;

  // typed arrays
  static final buffer = 'buffer'.toJS;
}

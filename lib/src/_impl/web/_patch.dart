import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS()
external JSAny? get location;

const _dbgIdProp = '@@dbgid';

void setDbgId(JSObject obj, String id) {
  obj[_dbgIdProp] = id.toJS;
}

String getDbgId(JSObject obj) {
  return obj.has(_dbgIdProp)
      ? obj[_dbgIdProp].dartify().toString()
      : '($_dbgIdProp not set)';
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

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const _dbgIdProp = '@@dbgid';

void setDbgId(JSObject obj, String id) {
  obj[_dbgIdProp] = id.toJS;
}

String getDbgId(JSObject obj) {
  return obj.has(_dbgIdProp)
      ? obj[_dbgIdProp].dartify().toString()
      : '($_dbgIdProp not set)';
}

String getErrorEventMessage(String tracer, JSObject? obj,
    [String message = 'Unknown error']) {
  String msg;
  if (obj != null && obj.has('message')) {
    msg = obj['message']?.toString() ?? message;
  } else {
    msg = message;
  }
  Object? err;
  if (obj != null && obj.has('error')) {
    err = obj['error'].dartify();
  } else {
    err = null;
  }
  print('[$tracer] ERROR MESSAGE ${obj.runtimeType} $obj $msg / $err');
  return msg;
}

Object? getErrorEventError(String tracer, JSObject? obj) {
  String msg;
  if (obj != null && obj.has('message')) {
    msg = obj['message']?.toString() ?? '???';
  } else {
    msg = '???';
  }
  Object? err;
  if (obj != null && obj.has('error')) {
    err = obj['error'].dartify();
  } else {
    err = null;
  }
  print('[$tracer] ERROR ${obj.runtimeType} $obj $err / $msg');
  return err;
}

List getMessageEventData(String tracer, JSObject? obj) {
  Object? data;
  if (obj != null && obj.has('data')) {
    data = (obj['data'].dartify() ?? const []);
  } else {
    data = const [];
  }
  print('[$tracer] MESSAGE ${obj.runtimeType} $obj $data');
  return data as List;
}

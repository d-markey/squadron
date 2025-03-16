import 'dart:collection';

import 'package:meta/meta.dart';

class SerializationContext {
  SerializationContext(bool Function(Object, Object) identical)
      : _cache = HashMap(equals: identical);

  final HashMap<Object, Object> _cache;

  T? getReference<T extends Object>(Object data) {
    final ref = _cache[data];
    return (ref is T) ? ref : null;
  }

  void setReference<T extends Object>(Object data, T instance) {
    _cache[data] = instance;
  }
}

@internal
extension SerializationContextImpl on SerializationContext {
  void reset() => _cache.clear();

  Map<Object, Object> get cache => _cache;
}

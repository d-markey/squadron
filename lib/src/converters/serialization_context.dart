import 'dart:collection';

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

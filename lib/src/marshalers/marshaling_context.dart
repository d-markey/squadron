import '../converters/context_aware_converter.dart';
import '../converters/converter.dart';
import '../converters/serialization_context.dart';
import '../squadron_singleton.dart';
import '../typedefs.dart';

/// Marshaling context. Context-aware marshalers can register marshaled /
/// unmarshaled instances; if the same input is encountered, the same instance
/// can be fetched from the context instead of marshaling/unmarshaling a fresh
/// instance. Context-aware marshalers can be used where object identities
/// matter. Additionally, they also help support serialization of instances
/// that bear cyclical dependencies.
class MarshalingContext {
  MarshalingContext({bool contextAware = true})
      : _converter =
            contextAware ? ContextAwareConverter() : Squadron.converter,
        _objects = contextAware ? SerializationContext(identical) : null;

  /// [none] can be used as a context-unaware converter.
  static const MarshalingContext? none = null;

  /// [Converter] to convert data before marshaling/unmarshaling. In a context-
  /// aware marshaling context, the converter also keeps track of raw data
  /// received from / sent to the worker
  final Converter _converter;

  final SerializationContext? _objects;

  /// Whether this context is context-aware.
  bool get isContextAware => _objects != null;

  /// Get the instance that was registered for the same [data].
  T? getReference<T extends Object>(dynamic data) =>
      _objects?.getReference(data);

  /// Register [instance] for this [data].
  void setReference<T extends Object>(dynamic data, T instance) =>
      _objects?.setReference(data, instance);
}

/// Make MarshalingContext? a converter
extension ConverterExt on MarshalingContext? {
  Converter get converter => this?._converter ?? Squadron.converter;

  Cast<T> value<T extends Object>() => converter.value<T>();

  Cast<List<T>> list<T extends Object>([Cast<T>? cast]) =>
      converter.list<T>(cast);

  Cast<List<T?>> nlist<T extends Object>([Cast<T>? cast]) =>
      converter.nlist(cast);

  Cast<Set<T>> set<T extends Object>([Cast<T>? cast]) => converter.set<T>(cast);

  Cast<Set<T?>> nset<T extends Object>([Cast<T>? cast]) => converter.nset(cast);

  Cast<Map<K, V>> map<K extends Object, V extends Object>(
          {Cast<K>? kcast, Cast<V>? vcast}) =>
      converter.map<K, V>(kcast: kcast, vcast: vcast);

  Cast<Map<K, V?>> nmap<K extends Object, V extends Object>(
          {Cast<K>? kcast, Cast<V>? vcast}) =>
      converter.nmap<K, V>(kcast: kcast, vcast: vcast);
}

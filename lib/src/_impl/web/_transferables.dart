import '../../exceptions/squadron_error.dart';

class Transferables {
  const Transferables._();

  static List<Object>? get(List args) {
    final objects = _get(args, <Object>{}).toList();
    return objects.isEmpty ? null : objects;
  }

  static bool _isBaseType(Object? data) =>
      (data == null || data is String || data is num || data is bool);

  static bool _isListOfBaseType(Object? data) =>
      (data is List<String> || data is List<num> || data is List<bool>);

  static bool _isSafeForTransfer(Object? data) {
    if (_isBaseType(data)) return true;
    if (_isListOfBaseType(data)) return true;
    if (data is List && data.every(_isSafeForTransfer)) return true;
    return false;
  }

  static bool _isNotSafeForTransfer(Object? data) => !_isSafeForTransfer(data);

  /// Excludes base type values from [list].
  static Iterable<Object> _getObjects(Iterable list, Set<Object> seen) sync* {
    for (var o in list.where(_isNotSafeForTransfer)) {
      if (!seen.contains(o)) {
        seen.add(o);
        yield o as Object;
      }
    }
  }

  static void _checkKeys(Map data) {
    if (!data.keys.every(_isBaseType)) {
      throw SquadronErrorImpl.create(
          'Map keys must be strings, numbers or booleans.');
    }
  }

  /// Yields objects contained in [message]. Used to identify non-base type objects and provide
  /// them to [Worker.postMessage]. [Worker.postMessage] will clone these objects. The code makes
  /// no effort to ensure these objects really are transferable.
  static Iterable<Object> _get(List message, Set<Object> seen) sync* {
    if (_isSafeForTransfer(message)) return;
    final toBeInspected = _getObjects(message, seen).toList();
    var i = 0;
    while (i < toBeInspected.length) {
      final arg = toBeInspected[i++];
      if (arg is Map) {
        _checkKeys(arg);
        toBeInspected.addAll(_getObjects(arg.values, seen));
      } else if (arg is Iterable) {
        toBeInspected.addAll(_getObjects(arg, seen));
      } else {
        yield arg;
      }
    }
  }
}

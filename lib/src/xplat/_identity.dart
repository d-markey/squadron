import '../squadron.dart';

/// Singleton class used to generate unique IDs for workers.
///
/// The class implements a simple counter that is incremented each time a new ID will be requested. Because of Dart's
/// architecture, this guarantees unicity per event loop (thread) only.
class Identity {
  Identity._();

  static final _instance = Identity._();

  int _counter = 0;

  /// Provides the next ID.
  static String nextId() {
    final id = ++_instance._counter;
    return '${Squadron.id}.$id';
  }
}

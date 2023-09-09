import '../../squadron.dart';

/// Singleton class used to generate unique IDs for workers.
///
/// The class implements a simple counter that is incremented each time a new ID will be requested. The generated
/// ID also integrates [Squadron.id] to guarantee unicity across event loops (provided [Squadron.id]s are also
/// unique across event loops).
class WorkerId {
  WorkerId._();

  static final _instance = WorkerId._();

  int _counter = 0;

  /// Provides the next ID.
  static String next() {
    final id = ++_instance._counter;
    return '${Squadron.id}.$id';
  }
}

/// Singleton class used to generate unique IDs for cancellation tokens.
///
/// The class implements a simple counter that is incremented each time a new ID will be requested. Because of Dart's
/// architecture, this guarantees unicity per event loop (thread) only. If the [SequenceId] is used from an Isolate
/// or a Web Worker, IDs may overlap across threads. This may be a problem in complex scenarios where workers invoke
/// other workers while creating their own cancellation tokens. Ideally, workers should forward the cancellation token
/// they received when calling other workers.
class SequenceId {
  SequenceId._();

  static final _instance = SequenceId._();

  int _id = 0;

  /// Provides the next ID.
  static int next() => ++_instance._id;
}

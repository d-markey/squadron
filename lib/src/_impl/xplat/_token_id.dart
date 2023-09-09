import '../../squadron.dart';

/// Singleton class used to generate unique IDs for cancellation tokens.
///
/// The class implements a simple counter that is incremented each time a new ID will be requested. The generated
/// ID also integrates [Squadron.id] to guarantee unicity across event loops (provided [Squadron.id]s are also
/// unique across event loops). Workers should forward the cancellation token they received when calling other
/// workers.
class TokenId {
  TokenId._();

  static final _instance = TokenId._();

  int _id = 0;

  /// Provides the next ID.
  static String next() {
    final id = ++_instance._id;
    return '$id@${Squadron.id}';
  }
}

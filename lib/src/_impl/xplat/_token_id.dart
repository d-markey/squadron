/// Singleton class used to generate unique IDs for cancelation tokens.
///
/// The class implements a simple counter that is incremented each time a new
/// ID is requested. Workers should forward the cancelation token they received
/// when calling other workers.
class TokenId {
  TokenId._();

  static final _instance = TokenId._();

  int _id = 0;

  /// Provides the next ID.
  static String next() {
    final id = ++_instance._id;
    return '$id';
  }
}

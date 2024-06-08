import 'hex.dart';

/// Singleton class used to generate unique IDs for cancelation tokens.
///
/// The class implements a simple counter that is incremented each time a new
/// ID is requested. Workers should forward the cancelation token they received
/// when calling other workers.
class TokenId {
  TokenId._();

  static final _instance = TokenId._();
  static final _instanceId = _instance.hashCode.hex;

  int _id = 0;

  /// Provides the next ID.
  static String next() => '${++_instance._id}@$_instanceId';
}

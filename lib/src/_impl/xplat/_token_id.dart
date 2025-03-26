import 'package:meta/meta.dart';

import '_platform.dart';

/// Singleton class used to generate unique IDs for cancelation tokens.
///
/// The class implements a simple counter that is incremented each time a new
/// ID is requested. Workers should forward the cancelation token they received
/// when calling other workers.
@internal
class TokenId {
  TokenId._();

  static int _id = 0;

  /// Provides the next ID.
  static String next() => '${++_id}@$threadId';
}

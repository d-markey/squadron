import 'cancellation_token.dart';

@Deprecated('Use CancellationToken instead')
class CancellableToken extends CancellationToken {
  CancellableToken(int id, [String? message]) : super(message) {
    withId(id);
  }
}

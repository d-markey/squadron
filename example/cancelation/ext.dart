import 'package:cancelation_token/cancelation_token.dart';

extension CancelationTokenStatusExt on CancelationToken? {
  String get status => (this?.isCanceled ?? false) ? 'cancelled' : 'pending';
}

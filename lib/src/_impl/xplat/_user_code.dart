import 'package:logger/logger.dart';

class UserCode {
  UserCode._();

  static void _log(Logger? logger, dynamic logContext, dynamic ex) {
    if (logger != null && logContext != null) {
      final message =
          ((logContext is Function) ? logContext() : logContext)?.toString() ??
              '';
      logger.e('User code threw an exception ($message): $ex');
    }
  }

  static void _noop(dynamic _) {}

  static T? run<T>(Logger? logger, T Function() callback,
      [dynamic logContext]) {
    try {
      final res = callback();
      if (res is Future) {
        res.then(_noop, onError: (ex) => _log(logger, logContext, ex));
      }
      return res;
    } catch (ex) {
      _log(logger, logContext, ex);
      return null;
    }
  }
}

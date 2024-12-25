import 'dart:async';

import 'package:squadron/squadron.dart';

/// It is recommended to annotate this class with @[SquadronService] and
/// use package squadron_builder to avoid manual implementation of the
/// worker service, worker and worker pool.
///
/// See https://github.com/d-markey/squadron_builder/tree/main/example/hello_world
///
/// The service class.
class HelloWorld {
  /// It is recommended to annotate this method with @[squadronMethod] and
  /// use package squadron_builder to generate the code.
  ///
  /// [threadId] is an hex string that should be unique to each worker thread.
  ///
  /// A service method.
  Future<String> sayHello(String? name,
      {int delayInSec = 0, bool echo = false}) async {
    if (delayInSec > 0) {
      await Future.delayed(Duration(seconds: delayInSec));
    }
    name = name?.trim() ?? '';
    if (echo) {
      print('Saying hello to $name');
    }
    return 'Hello, ${name.isEmpty ? 'World' : name} from thread $threadId!';
  }
}

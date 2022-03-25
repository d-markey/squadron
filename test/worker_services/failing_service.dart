import 'dart:async';

import 'package:squadron/squadron.dart';

class FailingService implements WorkerService {
  FutureOr noop() {
    Squadron.shout('noop');
  }

  static const noopCommand = 1;

  @override
  late final Map<int, CommandHandler> operations = {
    noopCommand: (r) => noop(),
  };
}

extension RunnerMessage on String {
  static String launch(List<String> tests) => '$run\n${tests.join('\n')}';

  static const run = '@@RUN@@';
  static const cancel = '@@CANCEL@@';
  static const clear = '@@CLEAR@@';
  static const ready = '@@READY@@';
  static const started = '@@STARTED@@';
  static const done = '@@DONE@@';

  static const nextError = '@@NEXT-ERROR@@';
  static const previousError = '@@PREV-ERROR@@';

  Iterable<String> get tests {
    final parts = split('\n');
    if (parts[0] == run) {
      parts.removeAt(0);
      return parts;
    } else {
      return const [];
    }
  }
}

import 'dart:async';

class CancellationToken {
  CancellationToken(this.token);

  static const _$token = 'a';

  static CancellationToken? deserialize(Map? token) => token == null
      ? null
      : CancellationToken(token[_$token]);

  final bool isTimeout = false;

  final int token;
  final cancelled = false;

  String? get message => null;

  Map serialize() => {_$token: token};

  void start({FutureOr Function()? onTimeout}) {}

  void stop() {}

  void addListener(FutureOr Function() listener) {}

  void removeListener(FutureOr Function() listener) {}
}

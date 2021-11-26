class CancellationToken {
  CancellationToken(this.token);

  static const _$token = 'a';

  static CancellationToken? deserialize(Map? token) =>
      token == null ? null : CancellationToken(token[_$token]);

  final bool isTimeout = false;

  final int token;
  final cancelled = false;

  String? get message => null;

  Map serialize() => {_$token: token};

  void start({void Function()? onTimeout}) {}

  void stop() {}

  void addListener(void Function() listener) {}

  void removeListener(void Function() listener) {}
}

import 'package:squadron/squadron.dart';

class TestException extends WorkerException {
  TestException(super.message, [super.stackTrace, super.command]);

  static const typeId = '#TEST';

  @override
  List serialize() => List.unmodifiable([
        typeId,
        message,
        stackTrace?.toString(),
        command,
      ]);

  static TestException? deserialize(List data) {
    if (data[0] == typeId) {
      return TestException(
        data[1],
        SquadronException.loadStackTrace(data[2]),
        data[3]?.toInt(),
      );
    }
    return null;
  }
}

import 'package:squadron/squadron.dart';

class CustomException extends WorkerException {
  CustomException(super.message, [super.stackTrace, super.command]);

  static const typeId = 'CUSTOM';

  @override
  List serialize() => List.unmodifiable([
        typeId,
        message,
        stackTrace?.toString(),
        command,
      ]);

  static CustomException? deserialize(List data) {
    if (data[0] == typeId) {
      return CustomException(
        data[1],
        SquadronException.loadStackTrace(data[2]),
        data[3]?.toInt(),
      );
    }
    return null;
  }
}

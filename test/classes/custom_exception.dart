import 'package:squadron/squadron.dart';

class CustomException extends WorkerException {
  CustomException(super.message, {super.stackTrace});

  static const typeId = 'CUSTOM';

  @override
  List serialize() => List.unmodifiable([
        typeId,
        message,
        stackTrace?.toString(),
      ]);

  static CustomException? deserialize(List data) {
    if (data[0] == typeId) {
      return CustomException(data[1],
          stackTrace: SquadronException.loadStackTrace(data[2]));
    }
    return null;
  }
}

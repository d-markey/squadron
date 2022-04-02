import 'package:squadron/squadron.dart';

class CustomException extends WorkerException {
  CustomException(String message, {StackTrace? stackTrace})
      : super(message, stackTrace: stackTrace);

  @override
  List serialize() => ['CUSTOM', message, stackTrace?.toString()];

  static CustomException? deserialize(List data) {
    if (data[0] == 'CUSTOM') {
      return CustomException(data[1],
          stackTrace: SquadronException.loadStackTrace(data[2]));
    }
    return null;
  }
}

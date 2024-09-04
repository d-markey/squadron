import 'package:squadron/squadron.dart';

void unsendable() {}

dynamic getUnsendable() => unsendable;

void setConverter(WorkerRequest startReq) {
  final useNumConverter = platformConverter.v<bool>()(startReq.args[0]);
  platformConverter =
      useNumConverter ? NumConverter.instance : CastConverter.instance;
}

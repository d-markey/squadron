import 'package:squadron/squadron.dart';

void unsendable() {}

dynamic getUnsendable() => unsendable;

final String threadId = Object().hashCode.hex; // unique per event loop

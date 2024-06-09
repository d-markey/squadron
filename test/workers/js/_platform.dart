import 'package:squadron/squadron.dart';

class Unsendable {}

dynamic getUnsendable() => Unsendable();

final String threadId = Object().hashCode.hex; // unique per event loop

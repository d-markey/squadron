import 'package:squadron/squadron.dart';

final entryPoint = InProcEntryPoint(_start);

void _start(dynamic args) {
  print('I\'m not a worker!');
}

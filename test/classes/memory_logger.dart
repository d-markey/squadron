import 'package:squadron/squadron_service.dart';

class MemoryLogger extends BaseSquadronLogger {
  final _messages = <String>[];

  void clear() => _messages.clear();

  bool contains(String text) => _messages.any((m) => m.contains(text));

  int get length => _messages.length;

  @override
  void log(dynamic message) => _messages.add(message?.toString() ?? '');

  @override
  String toString() => _messages.join('\n');
}

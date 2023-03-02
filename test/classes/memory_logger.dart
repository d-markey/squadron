import 'package:squadron/squadron_service.dart';

class MemoryLogger extends BaseSquadronLogger {
  final _messages = <String>[];

  void clear() => _messages.clear();

  bool contains(String text) => _messages.any((m) => m.contains(text));

  int get length => _messages.length;

  List<String> get messages => List.unmodifiable(_messages);

  @override
  Iterable<String> format(int level, dynamic message) {
    final header = '[${Squadron.id}]';
    if (message is Iterable) {
      message = message
          .map((m) => m?.toString() ?? '')
          .expand((m) => m.toString().split('\n'));
    } else {
      message = message?.toString().split('\n') ?? const [];
    }
    return message.where((m) => m.isNotEmpty).map((line) => '$header $line');
  }

  @override
  void log(String message) {
    _messages.add(message);
  }

  @override
  String toString() => _messages.join('\n');
}

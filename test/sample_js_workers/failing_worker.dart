import 'package:squadron/squadron_service.dart';

void main() => run((startRequest) {
      Squadron.logger = ConsoleSquadronLogger();
      throw Exception('Intentional failure');
    });

import 'package:squadron/squadron_service.dart';

void start(Map command) => run((startRequest) {
      Squadron.logger = ConsoleSquadronLogger();
      throw Exception('Intentional failure');
    }, command);

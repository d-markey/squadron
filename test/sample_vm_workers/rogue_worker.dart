import 'package:squadron/squadron_service.dart';

import '../worker_services/rogue_service.dart';

void start(Map command) {
  run((startRequest) => RogueService(), command);
}

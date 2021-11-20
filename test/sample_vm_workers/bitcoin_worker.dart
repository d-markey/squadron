import 'package:squadron/squadron_service.dart';

import '../worker_services/bitcoin_service.dart';

void start(Map command) => run((startRequest) => BitcoinService(), command);

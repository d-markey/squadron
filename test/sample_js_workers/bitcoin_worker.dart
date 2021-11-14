import 'package:squadron/squadron_service.dart';

import '../worker_services/bitcoin_service.dart';

void main() {
  run((startRequest) => BitcoinService(), const {});
}

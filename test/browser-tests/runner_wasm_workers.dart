import 'package:squadron/squadron.dart';

import 'runner.dart' as runner;

void main(dynamic args) async {
  await runner.bootstrap(workerPlatform: SquadronPlatformType.wasm);
}

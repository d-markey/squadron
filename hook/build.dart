import 'package:squadron_build_hook/squadron_build_hook.dart';

void main(List<String> args) async =>
    await runSquadronBuildHook(args, concurrency: 3);

import 'package:squadron/squadron.dart';

class TestEntryPoints {
  EntryPoint? echo;
  EntryPoint? inMemory;
  EntryPoint? native;
  EntryPoint? notAWorker;
  EntryPoint? missingWorker;

  EntryPoint? cache;
  EntryPoint? installable;
  EntryPoint? issues;
  EntryPoint? local;
  EntryPoint? prime;

  EntryPoint? test;
  EntryPoint? failedInit;
  EntryPoint? invalidCommand;
  EntryPoint? missingStartRequest;

  Iterable<EntryPoint> get defined => [
        echo,
        inMemory,
        native,
        notAWorker,
        cache,
        installable,
        issues,
        local,
        prime,
        test,
        failedInit,
        invalidCommand,
        missingStartRequest,
      ].where((e) => e != null).cast<EntryPoint>();
}

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

  EntryPoint? log;
  EntryPoint? streaming;
  EntryPoint? test;
  EntryPoint? person;

  EntryPoint? errors;
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
        log,
        streaming,
        test,
        person,
        errors,
        missingStartRequest,
      ].nonNulls;
}

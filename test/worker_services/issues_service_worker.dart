import 'package:squadron/squadron.dart';

import 'issues_service.dart';
import 'worker_entry_points.dart';

class IssuesWorkerPool extends WorkerPool<IssuesWorker>
    implements IssuesService {
  IssuesWorkerPool([ConcurrencySettings? concurrencySettings])
      : super(() => IssuesWorker(),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  Stream<dynamic> issue_8(List<dynamic> words) =>
      stream((w) => w.issue_8(words));
}

class IssuesWorker extends Worker implements IssuesService {
  IssuesWorker() : super(EntryPoints.issues);

  @override
  Stream<dynamic> issue_8(List<dynamic> words) =>
      stream(IssuesService.cmdIssue_8, args: [words]);
}

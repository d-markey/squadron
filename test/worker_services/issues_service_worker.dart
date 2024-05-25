import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'issues_service.dart';

class IssuesWorkerPool extends WorkerPool<IssuesWorker>
    implements IssuesService {
  IssuesWorkerPool(TestContext context,
      [ConcurrencySettings? concurrencySettings])
      : super(() => IssuesWorker(context),
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  Stream<dynamic> issue_8(List<dynamic> words) =>
      stream((w) => w.issue_8(words));
}

class IssuesWorker extends Worker implements IssuesService {
  IssuesWorker(TestContext context) : super(context.entryPoints.issues!);

  @override
  Stream<dynamic> issue_8(List<dynamic> words) =>
      stream(IssuesService.cmdIssue_8, args: [words]);
}

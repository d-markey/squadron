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
  Stream<Map<String, int>> issue_8(List<int> nums) =>
      stream((w) => w.issue_8(nums));
}

class IssuesWorker extends Worker implements IssuesService {
  IssuesWorker(TestContext context) : super(context.entryPoints.issues!);

  @override
  Stream<Map<String, int>> issue_8(List<int> nums) =>
      stream(IssuesService.cmdIssue_8, args: [nums])
          .map(Squadron.converter.map<String, int>());
}

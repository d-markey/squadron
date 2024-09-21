import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'issues_service.dart';

base class IssuesWorkerPool extends WorkerPool<IssuesWorker>
    implements IssuesService {
  IssuesWorkerPool(TestContext context,
      [ConcurrencySettings? concurrencySettings])
      : super(
            (ExceptionManager exceptionManager, [Logger? logger]) =>
                IssuesWorker(
                  context,
                  exceptionManager: exceptionManager,
                )..channelLogger = logger,
            concurrencySettings:
                concurrencySettings ?? ConcurrencySettings.threeCpuThreads);

  @override
  Stream<Map<String, int>> issue_8(List<int> nums) =>
      stream((w) => w.issue_8(nums));
}

base class IssuesWorker extends Worker implements IssuesService {
  IssuesWorker(TestContext context, {ExceptionManager? exceptionManager})
      : super(context.entryPoints.issues!, exceptionManager: exceptionManager);

  @override
  Stream<Map<String, int>> issue_8(List<int> nums) =>
      stream(IssuesService.cmdIssue_8, args: [nums])
          .map(Squadron.converter.map<String, int>());
}

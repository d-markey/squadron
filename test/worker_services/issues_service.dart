import 'dart:async';

import 'package:squadron/squadron.dart';

class IssuesService implements WorkerService {
  Stream<Map<String, int>> issue_8(List<int> nums) async* {
    int id = 0;
    for (var n in nums) {
      await Future.delayed(Duration.zero);
      if (id == 2) throw 'issue 8 error message';
      id++;
      yield {'id': id, 'num': n};
    }
  }

  // command IDs
  static const cmdIssue_8 = 1;

  // command IDs --> command implementations
  @override
  Map<int, CommandHandler> get operations => {
        cmdIssue_8: (r) => issue_8(Squadron.converter.l<int>()(r.args[0])),
      };
}

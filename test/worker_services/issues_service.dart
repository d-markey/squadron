import 'package:squadron/squadron_service.dart';

class IssuesService implements WorkerService {
  Stream<dynamic> issue_8(List<dynamic> words) async* {
    int id = 0;
    for (var word in words) {
      await Future.delayed(Duration.zero);
      if (id == 2) throw 'issue 8 error message';
      id++;
      yield word;
    }
  }

  // command IDs
  static const cmdIssue_8 = 1;

  // command IDs --> command implementations
  @override
  Map<int, CommandHandler> get operations => {
        cmdIssue_8: (r) => issue_8(r.args[0]),
      };
}

import 'dart:async';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';

import 'squadron_version.dart';

class IssuesService with SquadronVersion implements WorkerService {
  Stream<Map<String, int>> issue_8(List<int> nums) async* {
    int id = 0;
    for (var n in nums) {
      await Future.delayed(Duration.zero);
      if (id == 2) throw 'issue 8 error message';
      id++;
      yield {'id': id, 'num': n};
    }
  }

  FutureOr<ByteBuffer?> issue_23(
    final List<int> bytes, {
    final String? title,
    final bool isLandscape = true,
    final List<String>? columns,
    final Map<int, double>? columnWidths,
    final ByteData? fontData,
    final Map<int, ByteData>? titleFonts,
    final Map<int, ByteData>? dataFonts,
  }) async =>
      null;

  // command IDs
  static const cmdIssue_8 = 1;
  static const cmdIssue_23 = 2;

  // command IDs --> command implementations
  @override
  late final operations = OperationsMap({
    SquadronVersion.versionCommand: (r) => getVersion(),
    cmdIssue_8: (r) => issue_8(
          Squadron.converter.list<int>()(r.args[0]),
        ),
    cmdIssue_23: (r) {
      final converter = ContextAwareConverter();
      return issue_23(
        converter.list<int>()(r.args[0]),
        title: r.args[1],
        isLandscape: r.args[2],
        columns: Converter.allowNull(converter.list<String>())(r.args[3]),
        columnWidths:
            Converter.allowNull(converter.map<int, double>())(r.args[4]),
        fontData: Converter.allowNull(converter.value<ByteData>())(r.args[5]),
        titleFonts:
            Converter.allowNull(converter.map<int, ByteData>())(r.args[6]),
        dataFonts:
            Converter.allowNull(converter.map<int, ByteData>())(r.args[7]),
      );
    },
  });
}

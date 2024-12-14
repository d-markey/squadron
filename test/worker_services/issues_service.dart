import 'dart:async';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';

class IssuesService implements WorkerService {
  IssuesService() {
    operations.addAll({
      cmdIssue_8: (r) => issue_8(
            $X.listOfInt(r.args[0]),
          ),
      cmdIssue_23: (r) => issue_23(
            $X.listOfInt(r.args[0]),
            title: r.args[1],
            isLandscape: r.args[2],
            columns: $X.nullableListOfString(r.args[3]),
            columnWidths: $X.nullableMapOfIntDouble(r.args[4]),
            fontData: $X.nullableBytedata(r.args[5]),
            titleFonts: $X.nullableMapOfIntBytedata(r.args[6]),
            dataFonts: $X.nullableMapOfIntBytedata(r.args[7]),
          ),
    });
  }
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
  final Map<int, CommandHandler> operations = {};
}

class $X {
  static final listOfInt = Squadron.converter.list<int>();
  static final nullableListOfString =
      Squadron.converter.nullable(Squadron.converter.list<String>());
  static final nullableMapOfIntDouble =
      Squadron.converter.nullable(Squadron.converter.map<int, double>());
  // ignore: prefer_function_declarations_over_variables
  static final bytedata =
      ($) => (const TypedDataMarshaler<ByteData>()).unmarshal($);
  static final nullableBytedata = Squadron.converter.nullable(bytedata);
  static final nullableMapOfIntBytedata = Squadron.converter
      .nullable(Squadron.converter.map<int, ByteData>(vcast: bytedata));
}

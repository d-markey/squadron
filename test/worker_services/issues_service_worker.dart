import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:squadron/squadron.dart';

import '../src/test_context.dart';
import 'issues_service.dart';
import 'squadron_version.dart';

base class IssuesWorkerPool extends WorkerPool<IssuesWorker>
    with PoolVersion<IssuesWorker>
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

  @override
  Future<ByteBuffer?> issue_23(
    final List<int> bytes, {
    final String? title,
    final bool isLandscape = true,
    final List<String>? columns,
    final Map<int, double>? columnWidths,
    final ByteData? fontData,
    final Map<int, ByteData>? titleFonts,
    final Map<int, ByteData>? dataFonts,
  }) async =>
      execute((w) => w.issue_23(
            bytes,
            title: title,
            isLandscape: isLandscape,
            columns: columns,
            columnWidths: columnWidths,
            fontData: fontData,
            titleFonts: titleFonts,
            dataFonts: dataFonts,
          ));
}

base class IssuesWorker extends Worker
    with WorkerVersion
    implements IssuesService {
  IssuesWorker(TestContext context, {ExceptionManager? exceptionManager})
      : super(context.entryPoints.issues!, exceptionManager: exceptionManager);

  @override
  Stream<Map<String, int>> issue_8(List<int> nums) =>
      stream(IssuesService.cmdIssue_8, args: [nums])
          .map(Squadron.converter.map<String, int>());

  @override
  Future<ByteBuffer?> issue_23(
    final List<int> bytes, {
    final String? title,
    final bool isLandscape = true,
    final List<String>? columns,
    final Map<int, double>? columnWidths,
    final ByteData? fontData,
    final Map<int, ByteData>? titleFonts,
    final Map<int, ByteData>? dataFonts,
  }) =>
      send(IssuesService.cmdIssue_23, args: [
        $X.list(bytes),
        title,
        isLandscape,
        $X.nullableList(columns),
        $X.nullableMap(columnWidths),
        $X.nullableBytedata(fontData),
        $X.nullableMapOfBytedata(titleFonts),
        $X.nullableMapOfBytedata(dataFonts),
      ]).then($X.bytebuffer);
}

class $X {
  static final list = Squadron.converter.list();
  static final nullableList = Squadron.converter.nullable(list);
  static final map = Squadron.converter.map();
  static final nullableMap = Squadron.converter.nullable(map);
  // ignore: prefer_function_declarations_over_variables
  static final bytedata =
      (x) => const TypedDataMarshaler<ByteData>().marshal(x);
  static final nullableBytedata = Squadron.converter.nullable(bytedata);
  static final mapOfBytedata = Squadron.converter.map(vcast: bytedata);
  static final nullableMapOfBytedata =
      Squadron.converter.nullable(mapOfBytedata);
  static final bytebuffer =
      Squadron.converter.nullable(Squadron.converter.value<ByteBuffer>());
}

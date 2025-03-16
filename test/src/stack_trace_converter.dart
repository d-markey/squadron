import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:source_map_stack_trace/source_map_stack_trace.dart';
import 'package:source_maps/parser.dart';

class StackTraceConverter {
  const StackTraceConverter._forward() : sourceMapping = null;

  StackTraceConverter._remap(this.sourceMapping);

  final Mapping? sourceMapping;

  static Future<StackTraceConverter> load(Uri? url) async {
    if (url != null) {
      final mapUri = Uri.parse('$url.map');
      final res = await http.get(mapUri);
      final mapping = parse(res.body);
      print('mappings = $mapping');
      return StackTraceConverter._remap(mapping);
    } else {
      return const StackTraceConverter._forward();
    }
  }

  StackTrace? convert(StackTrace? st) {
    if (st == null || sourceMapping == null) return st;
    return mapStackTrace(sourceMapping!, st);
  }
}

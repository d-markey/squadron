import '../../worker/entry_point.dart' as worker;

class WebEntryPoint extends worker.EntryPoint {
  const WebEntryPoint(this.url);

  final String url;
}

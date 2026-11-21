import '../../../worker/entry_point.dart' as worker;

class IpcEntryPoint extends worker.EntryPoint {
  const IpcEntryPoint(this.process);

  final String process;
}

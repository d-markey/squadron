final class TargetPlatform {
  static const vm = 1;
  static const js = 2;
  static const wasm = 4;

  static const web = js | wasm;
  static const all = vm | js | wasm;
}

extension TargetPlatformExt on int {
  bool get hasVm => (this & TargetPlatform.vm) != 0;
  bool get hasJs => (this & TargetPlatform.js) != 0;
  bool get hasWasm => (this & TargetPlatform.wasm) != 0;
}

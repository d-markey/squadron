enum SquadronPlatformType {
  unknown('Unknown'),
  vm('Dart VM'),
  js('JavaScript'),
  wasm('Web Assembly');

  const SquadronPlatformType(this.label);

  final String label;

  bool get isVm => this == vm;
  bool get isJs => this == js;
  bool get isWasm => this == wasm;
  bool get isWeb => isJs || isWasm;

  static SquadronPlatformType? tryParse(String label) {
    if (label == js.label) return js;
    if (label == wasm.label) return wasm;
    if (label == vm.label) return vm;
    if (label == unknown.label) return unknown;
    return null;
  }

  @override
  String toString() => label;
}

enum TestPlatform {
  unknown('Unknown'),
  vm('Native'),
  js('JavaScript'),
  wasm('WebAssembly');

  const TestPlatform(this.label);

  final String label;

  bool get isVm => this == vm;
  bool get isJs => this == js;
  bool get isWasm => this == wasm;
  bool get isJsOrWasm => isJs || isWasm;
}

extension HexExt on int {
  String get hex => '0x${toRadixString(16).padLeft(8, '0')}';
}

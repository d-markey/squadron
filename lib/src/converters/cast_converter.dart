import '../../squadron.dart';

class CastConverter extends Converter {
  const CastConverter();

  static const instance = CastConverter();

  @override
  Cast<T> value<T>() => Converter.identity<T>;
}

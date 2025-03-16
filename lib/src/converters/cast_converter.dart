import '../typedefs.dart';
import 'converter.dart';

class CastConverter extends Converter {
  const CastConverter();

  static const instance = CastConverter();

  @override
  Cast<T> value<T extends Object>() => Converter.identity<T>;
}

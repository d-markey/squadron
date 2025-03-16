import 'package:squadron/squadron.dart';

import 'country.dart';

class CountryMarshaler extends GenericMarshaler<Country> {
  const CountryMarshaler();

  @override
  dynamic marshal(Country data, [MarshalingContext? context]) {
    throw UnimplementedError();
  }

  @override
  Country unmarshal(dynamic data, [MarshalingContext? context]) {
    throw UnimplementedError();
  }
}

import 'package:squadron/squadron.dart';

import 'city.dart';

class CityMarshaler extends GenericMarshaler<City> {
  const CityMarshaler();

  @override
  dynamic marshal(City data, [MarshalingContext? context]) {
    throw UnimplementedError();
  }

  @override
  City unmarshal(dynamic data, [MarshalingContext? context]) {
    throw UnimplementedError();
  }
}

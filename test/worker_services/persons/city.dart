import 'package:meta/meta.dart';

import 'city_marshaler_stub.dart'
    if (dart.library.io) 'city_marshaler_vm.dart'
    if (dart.library.html) 'city_marshaler_web.dart'
    if (dart.library.js) 'city_marshaler_web.dart'
    if (dart.library.js_interop) 'city_marshaler_web.dart' as impl;
import 'country.dart';

typedef CityMarshaler = impl.CityMarshaler;

class City {
  City._(this.zip, this.name) : _country = null;

  City(this.zip, this.name, Country country) : _country = country;

  final String zip;
  final String name;

  Country? _country;
  Country? get country => _country;

  @override
  String toString() => 'City($name, $country)';
}

@internal
extension CityImpl on City {
  static City init(String zip, String name) => City._(zip, name);

  void setCountry(Country? country) => _country = country;
}

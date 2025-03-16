import 'country_marshaler_stub.dart'
    if (dart.library.io) 'country_marshaler_vm.dart'
    if (dart.library.html) 'country_marshaler_web.dart'
    if (dart.library.js) 'country_marshaler_web.dart'
    if (dart.library.js_interop) 'country_marshaler_web.dart' as impl;

typedef CountryMarshaler = impl.CountryMarshaler;

class Country {
  Country(this.id, this.name);

  final int id;
  final String name;

  @override
  String toString() => 'Country($id, $name)';
}

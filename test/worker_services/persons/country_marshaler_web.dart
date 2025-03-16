import 'package:squadron/squadron.dart';

import 'country.dart';

class CountryMarshaler extends SquadronMarshaler<Country, List> {
  const CountryMarshaler();

  @override
  List marshal(Country data, [MarshalingContext? context]) {
    var res = context?.getReference<List>(data);
    if (res != null) return res;
    res = [data.id, data.name];
    // set reference now before any further marshaling
    context?.setReference(data, res);
    return res;
  }

  @override
  Country unmarshal(List data, [MarshalingContext? context]) {
    var res = context?.getReference<Country>(data);
    if (res != null) return res;
    final toInt = context.converter.value<int>();
    final country = Country(toInt(data[0]), data[1]);
    // set reference now before any further unmarshaling
    context?.setReference(data, country);
    return country;
  }
}

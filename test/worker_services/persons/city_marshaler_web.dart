import 'package:squadron/squadron.dart';

import 'city.dart';
import 'country.dart';

class CityMarshaler extends SquadronMarshaler<City, List> {
  const CityMarshaler();

  final _countryMarshaler = const CountryMarshaler();

  @override
  List marshal(City data, [MarshalingContext? context]) {
    var res = context?.getReference<List>(data);
    if (res != null) return res;
    res = [
      data.zip,
      data.name,
      null,
    ];
    // set reference now before any further marshaling
    context?.setReference(data, res);
    if (data.country != null) {
      res[2] = _countryMarshaler.marshal(data.country!, context);
    }
    return res;
  }

  @override
  City unmarshal(List data, [MarshalingContext? context]) {
    var res = context?.getReference<City>(data);
    if (res != null) return res;
    res = CityImpl.init(data[0], data[1]);
    // set reference now before any further unmarshaling
    context?.setReference(data, res);
    res.setCountry(_countryMarshaler.unmarshal(data[2], context));
    return res;
  }
}

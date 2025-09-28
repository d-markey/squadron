part of 'person.dart';

class PersonMarshaler extends GenericMarshaler<Person> {
  const PersonMarshaler();

  final _cityMarshaler = const CityMarshaler();

  @override
  dynamic marshal(Person data, [MarshalingContext? context]) {
    var res = context?.getReference<List>(data);
    if (res != null) return res;

    res = [
      data.lastName, // 0
      data.firstName, // 1
      data.dateOfBirth, // 2
      null, // 3 - city
      null, // 4 - parent1
      null, // 5 - parent2
      [], // 6 - friends
    ];

    // set reference now before marshaling anything else
    context?.setReference(data, res);

    final pob = data.placeOfBirth;
    if (pob != null) res[3] = _cityMarshaler.marshal(pob, context);

    final p1 = data.parent1, p2 = data.parent2;
    if (p1 != null) res[4] = marshal(p1, context);
    if (p2 != null) res[5] = marshal(p2, context);
    (res[6] as List).addAll(data.friends.map((f) => marshal(f, context)));

    return res;
  }

  @override
  Person unmarshal(dynamic data, [MarshalingContext? context]) {
    data as List;
    var res = context?.getReference<Person>(data);
    if (res != null) return res;

    res = Person._(
      data[0],
      data[1],
      data[2],
    );

    // set reference now before unmarshaling anything else
    context?.setReference(data, res);

    if (data[3] != null) {
      res._placeOfBidth = _cityMarshaler.unmarshal(data[3], context);
    }

    Person $unmarshal(dynamic data) => unmarshal(data, context);

    if (data[4] != null) res._parent1 = $unmarshal(data[4]);
    if (data[5] != null) res._parent2 = $unmarshal(data[5]);
    res.setFriends(LazyInPlaceList(data[6], $unmarshal));
    return res;
  }
}

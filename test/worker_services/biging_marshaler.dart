import 'package:squadron/squadron.dart';

class BigIntMarshaler implements SquadronMarshaler<BigInt, String> {
  @override
  String marshal(BigInt data) => data.toString();

  @override
  BigInt unmarshal(String data) => BigInt.parse(data);
}

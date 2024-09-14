import 'package:squadron/squadron.dart';

class BigIntMarshaler extends SquadronMarshaler<BigInt, String> {
  const BigIntMarshaler();

  @override
  String marshal(BigInt data) => data.toString();

  @override
  BigInt unmarshal(String data) => BigInt.parse(data);
}

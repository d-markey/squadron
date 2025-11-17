import 'package:squadron/squadron.dart';

class Fraction {
  const Fraction._(this.numerator, this.denominator);

  static const zero = Fraction._(0, 0);

  factory Fraction(int numerator, int denominator) {
    if (denominator == 0) throw UnsupportedError('Division by zero');
    if (numerator == 0) return Fraction.zero;
    final d = numerator.gcd(denominator);
    return Fraction._(numerator ~/ d, denominator ~/ d);
  }

  final int numerator, denominator;

  Fraction operator +(Fraction other) => Fraction(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  @override
  bool operator ==(Object other) {
    if (other is Fraction) {
      return numerator == other.numerator && denominator == other.denominator;
    } else if (other is num) {
      if (numerator == 0) return other == 0;
      return other == (numerator / denominator);
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);
}

class FractionMarshaler extends SquadronMarshaler<Fraction, List<int>> {
  const FractionMarshaler();

  @override
  List<int> marshal(Fraction data, [MarshalingContext? context]) {
    var ref = context?.getReference<List<int>>(data);
    if (ref != null) return ref;
    ref = [data.numerator, data.denominator];
    context?.setReference(data, ref);
    return ref;
  }

  @override
  Fraction unmarshal(List<int> data, [MarshalingContext? context]) {
    var ref = context?.getReference<Fraction>(data);
    if (ref != null) return ref;
    final list = context.converter.list<int>()(data);
    ref = Fraction._(list[0], list[1]);
    context?.setReference(data, ref);
    return ref;
  }
}

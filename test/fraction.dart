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
      final val = numerator / denominator;
      return val == other;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);
}

class FractionMarshaler implements SquadronMarshaler<Fraction, List<int>> {
  const FractionMarshaler();

  @override
  List<int> marshal(Fraction data) => [data.numerator, data.denominator];

  @override
  Fraction unmarshal(List<int> data) => Fraction._(data[0], data[1]);
}

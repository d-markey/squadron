import 'package:meta/meta.dart';
import 'package:squadron/squadron.dart';
import 'package:squadron/src/converters/lazy_in_place_list.dart';

import 'city.dart';

part 'person_marshaler.dart';

class Person {
  Person._(this.lastName, this.firstName, this.dateOfBirth);

  Person(this.lastName, this.firstName, this.dateOfBirth, City placeOfBirth,
      Person? parent1, Person? parent2)
      : _placeOfBidth = placeOfBirth,
        _parent1 = parent1,
        _parent2 = parent2;

  final String lastName;
  final String firstName;
  final DateTime dateOfBirth;

  City? _placeOfBidth;
  City? get placeOfBirth => _placeOfBidth;

  Person? _parent1;
  Person? get parent1 => _parent1;

  Person? _parent2;
  Person? get parent2 => _parent2;

  List<Person>? _friends;
  List<Person> get friends => (_friends ??= []);

  bool isFriendOf(Person other) =>
      friends.contains(other) || other.friends.contains(this);

  bool isParentOf(Person other) =>
      other.parent1 == this || other.parent2 == this;

  bool isChildOf(Person other) => parent1 == other || parent2 == other;

  bool isSiblingOf(Person other) =>
      (parent1?.isParentOf(other) ?? false) ||
      (parent2?.isParentOf(other) ?? false);

  bool isStepSiblingOf(Person other) =>
      (parent1 != null && parent2 != null) &&
      (other.parent1 != null && other.parent2 != null) &&
      (((parent1?.isParentOf(other) ?? false) &&
              !(parent2?.isParentOf(other) ?? false)) ||
          (!(parent1?.isParentOf(other) ?? false) &&
              (parent2?.isParentOf(other) ?? false)));

  @override
  String toString() =>
      'Person($firstName, $lastName, $dateOfBirth, $parent1, $parent2)';
}

@internal
extension PersonImpl on Person {
  void setFriends(List<Person> friends) => _friends = friends;
}

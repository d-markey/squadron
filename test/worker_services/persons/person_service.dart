import 'dart:async';

import 'package:squadron/squadron.dart';

import '../squadron_version.dart';
import 'person.dart';

class PersonService with SquadronVersion implements WorkerService {
  Future<String> getKindType(Person person, Person other) async {
    if (identical(person, other)) return 'self';
    if (person.isParentOf(other)) return 'parent';
    if (person.isChildOf(other)) return 'child';
    if (person.isStepSiblingOf(other)) return 'step-sibling';
    if (person.isSiblingOf(other)) return 'sibling';
    if (person.isFriendOf(other)) return 'friend';
    if (person.friends.any(other.isFriendOf) ||
        other.friends.any(person.isFriendOf)) {
      return 'friend-of-friend';
    }
    return 'other';
  }

  // command IDs
  static const getKindTypeCommand = 1;

  // command IDs --> command implementations
  @override
  late final operations = OperationsMap({
    SquadronVersion.versionCommand: (r) => getVersion(),
    getKindTypeCommand: (r) {
      final cin = MarshalingContext();
      final marshaler = const PersonMarshaler();
      return getKindType(
        marshaler.unmarshal(r.args[0], cin),
        marshaler.unmarshal(r.args[1], cin),
      );
    },
  });
}

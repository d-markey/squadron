import 'package:squadron/squadron.dart';

import '../../worker_services/persons/person_service.dart';

void main() {
  run(
    (_) => PersonService(),
  );
}

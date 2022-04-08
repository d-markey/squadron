import 'package:squadron/squadron_service.dart';

import '../worker_services/issues_service.dart';

void main() => run((startRequest) => IssuesService());

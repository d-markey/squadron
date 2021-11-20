import 'package:squadron/squadron_service.dart';

import 'sample_service.dart';

void start(Map command) => run((startRequest) => SampleServiceImpl(), command);

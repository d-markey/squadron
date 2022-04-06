import 'package:squadron/squadron_local_worker.dart';

import '../worker_services/sample_service.dart';

void main() => run((startRequest) {
      final connectionInfo = startRequest.args[0];
      final loggerClient = LocalSquadronLoggerClient.connect(connectionInfo);
      if (loggerClient != null) {
        final logLevel = loggerClient.logLevel;
        Squadron.logger = loggerClient;
        Squadron.logLevel = logLevel;
      }
      return SampleService();
    });

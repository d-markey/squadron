import 'package:squadron/squadron.dart';

import '../../worker_services/issues_service.dart';
import '_platform.dart';

void main() => run((startReq) {
      setConverter(startReq);
      return IssuesService();
    });

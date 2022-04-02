import 'package:squadron/squadron_service.dart';

void main() => run((startRequest) {
      throw Exception('Intentional failure');
    });

import 'package:squadron/squadron.dart';

void main() => run((startRequest) {
      throw Exception('Intentional failure');
    });

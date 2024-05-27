import 'package:http/http.dart' as http;

class UriChecker {
  static Future<bool> exists(Uri url) async {
    try {
      final status = (await http.head(url)).statusCode;
      return (200 <= status) && (status < 300);
    } catch (_) {
      return false;
    }
  }
}

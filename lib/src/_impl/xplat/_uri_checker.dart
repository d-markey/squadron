import 'package:http/http.dart' as http;

class UriChecker {
  UriChecker._();

  static Future<bool> exists(Uri url) async {
    if (url.isScheme('data')) return true;
    try {
      final status = (await http.head(url)).statusCode;
      return (200 <= status) && (status < 300);
    } catch (_) {
      return false;
    }
  }
}

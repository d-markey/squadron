import 'package:http/browser_client.dart';

class UriChecker {
  static Future<bool> exists(Uri url) async {
    try {
      final status = (await BrowserClient().head(url)).statusCode;
      return (200 <= status) && (status < 300);
    } catch (_) {
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String productionBaseUrl =
      'https://quickmart-fmebhwgwcxfzhten.centralindia-01.azurewebsites.net';

  static String get baseUrl {
    if (!kIsWeb) return productionBaseUrl;
    final host = Uri.base.host;
    final isLocal = host == 'localhost' || host == '127.0.0.1';
    return isLocal ? productionBaseUrl : Uri.base.origin;
  }
}
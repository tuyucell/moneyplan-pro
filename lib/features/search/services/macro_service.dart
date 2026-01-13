import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class MacroService {
  final String baseUrl = ApiConstants.baseUrl; // http://localhost:8000

  Future<Map<String, dynamic>?> getMacroIndicators(String countryCode) async {
    try {
      // Örnek çağrı: http://localhost:8000/api/v1/macro/TR
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/macro/$countryCode'))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        debugPrint(
            'MacroService HTTP Error: ${response.statusCode} for $countryCode');
        return null;
      }
    } catch (e) {
      debugPrint('MacroService Error for $countryCode: $e');
      return null;
    }
  }
}

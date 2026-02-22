import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class SettingsService {
  static Future<String?> getSetting(String key) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/settings/$key'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['value']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar configuração $key: $e');
      return null;
    }
  }

  static Future<bool> updateSetting(String key, String value) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/settings/$key'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({'value': value}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao atualizar configuração $key: $e');
      return false;
    }
  }
}

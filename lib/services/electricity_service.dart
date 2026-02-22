import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/electricity_reading.dart';
import '../models/electricity_settings.dart';
import '../core/api_config.dart';

class ElectricityService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Buscar todas as leituras
  static Future<List<ElectricityReading>> getAllReadings() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.electricityUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ElectricityReading.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar leituras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Adicionar nova leitura
  static Future<ElectricityReading> addReading({
    required double counterValue,
    required double kwConsumed,
    required double pricePerKw,
    required double totalCost,
    String notes = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.electricityUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'counter_value': counterValue.toInt(), // Enviar como inteiro
          'kw_consumed': kwConsumed.toInt(), // Enviar como inteiro
          'price_per_kw': pricePerKw,
          'total_cost': totalCost,
          'reading_date': DateTime.now().toIso8601String(),
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ElectricityReading.fromJson(data);
      } else {
        throw Exception('Falha ao adicionar leitura: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar leitura existente
  static Future<ElectricityReading> updateReading({
    required int id,
    required double counterValue,
    required double kwConsumed,
    required double pricePerKw,
    required double totalCost,
    String notes = '',
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.electricityUrl}/$id'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'counter_value': counterValue.toInt(), // Enviar como inteiro
          'kw_consumed': kwConsumed.toInt(), // Enviar como inteiro
          'price_per_kw': pricePerKw,
          'total_cost': totalCost,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ElectricityReading.fromJson(data);
      } else {
        throw Exception('Falha ao atualizar leitura: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Excluir leitura
  static Future<void> deleteReading(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.electricityUrl}/$id'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Falha ao excluir leitura: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar leitura por ID
  static Future<ElectricityReading> getReadingById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.electricityUrl}/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ElectricityReading.fromJson(data);
      } else {
        throw Exception('Falha ao carregar leitura: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar configurações
  static Future<ElectricitySettings> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.electricitySettingsUrl),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ElectricitySettings.fromJson(data);
      } else {
        throw Exception(
          'Falha ao carregar configurações: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar configurações
  static Future<ElectricitySettings> updateSettings({
    required double defaultPricePerKw,
    required double vatRate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(ApiConfig.electricitySettingsUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'default_price_per_kw': defaultPricePerKw,
          'vat_rate': vatRate,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ElectricitySettings.fromJson(data);
      } else {
        throw Exception(
          'Falha ao atualizar configurações: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}

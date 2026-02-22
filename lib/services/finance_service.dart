import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/financial_record.dart';
import '../core/api_config.dart';

class FinanceService {
  // Buscar registos financeiros por período e tipo
  static Future<List<FinancialRecord>> getRecords({
    DateTime? start,
    DateTime? end,
    String? type,
  }) async {
    try {
      String url = ApiConfig.financeUrl;
      List<String> params = [];
      if (start != null) {
        params.add('start=${start.toIso8601String().split('T')[0]}');
      }
      if (end != null) {
        params.add('end=${end.toIso8601String().split('T')[0]}');
      }
      if (type != null) {
        params.add('type=$type');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FinancialRecord.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar registos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar novo registo
  static Future<FinancialRecord> createRecord(FinancialRecord record) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.financeUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(record.toJson()),
      );

      if (response.statusCode == 201) {
        return FinancialRecord.fromJson(json.decode(response.body));
      } else {
        throw Exception('Falha ao criar registo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Deletar registo
  static Future<void> deleteRecord(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.financeUrl}/$id'),
      );
      if (response.statusCode != 200) {
        throw Exception('Falha ao deletar registo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Obter relatório consolidado
  static Future<Map<String, dynamic>> getConsolidatedReport(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.financeUrl}/report?start=${start.toIso8601String().split('T')[0]}&end=${end.toIso8601String().split('T')[0]}',
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Falha ao gerar relatório: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}

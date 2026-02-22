import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recado.dart';
import '../core/api_config.dart';

class RecadoService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<List<Recado>> getAll() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.recadosUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Recado.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar recados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Recado> add(Recado recado) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.recadosUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(recado.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Recado.fromJson(data);
      } else {
        throw Exception('Falha ao adicionar recado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Recado> update(Recado recado) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.recadosUrl}/${recado.id}'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(recado.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Recado.fromJson(data);
      } else {
        throw Exception('Falha ao atualizar recado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<void> delete(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.recadosUrl}/$id'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Falha ao excluir recado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}

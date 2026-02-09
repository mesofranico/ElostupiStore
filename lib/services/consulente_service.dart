import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/consulente.dart';
import '../models/consulente_session.dart';
import '../core/api_config.dart';

class ConsulentesService {

  // Buscar todos os consulentes
  static Future<List<Consulente>> getAllConsulentes() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.consulentesUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Consulente.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar consulentes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar consulente por ID
  static Future<Consulente> getConsulenteById(int id) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.consulentesUrl}/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Consulente.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Consulente não encontrado');
      } else {
        throw Exception('Falha ao carregar consulente: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar novo consulente
  static Future<Consulente> createConsulente(Consulente consulente) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.consulentesUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(consulente.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Consulente.fromJson(data);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? 'Erro desconhecido';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar consulente
  static Future<Consulente> updateConsulente(Consulente consulente) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.consulentesUrl}/${consulente.id}'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(consulente.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Consulente.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Consulente não encontrado');
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? 'Erro desconhecido';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  // Deletar consulente
  static Future<void> deleteConsulente(int id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.consulentesUrl}/$id'));
      
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Consulente não encontrado');
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? 'Erro desconhecido';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar sessões de um consulente
  static Future<List<ConsulenteSession>> getConsulenteSessions(int consulenteId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.consulentesUrl}/$consulenteId/sessions'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> sessions = data['sessions'];
        return sessions.map((json) => ConsulenteSession.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw Exception('Consulente não encontrado');
      } else {
        throw Exception('Falha ao carregar sessões: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar nova sessão
  static Future<ConsulenteSession> createSession(ConsulenteSession session) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.consulentesUrl}/${session.consulenteId}/sessions'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(session.toJson()),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ConsulenteSession.fromJson(data);
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? 'Erro desconhecido';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar sessão
  static Future<ConsulenteSession> updateSession(ConsulenteSession session) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.consulentesUrl}/sessions/${session.id}'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(session.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ConsulenteSession.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Sessão não encontrada');
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? 'Erro desconhecido';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  // Deletar sessão
  static Future<void> deleteSession(int sessionId) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.consulentesUrl}/sessions/$sessionId'));
      
      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Sessão não encontrada');
      } else {
        String errorMessage = 'Erro desconhecido';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? 'Erro desconhecido';
        } catch (e) {
          errorMessage = 'Erro ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }
}

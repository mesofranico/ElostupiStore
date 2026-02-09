import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_record.dart';
import '../models/consulente.dart';
import '../models/consulente_session.dart';
import '../core/api_config.dart';

class AttendanceService {
  static Future<List<AttendanceRecord>> getAttendanceByDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${ApiConfig.attendanceUrl}/date/$dateString'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar presenças: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar presenças: $e');
    }
  }

  static Future<List<AttendanceRecord>> getAttendanceByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final startString = startDate.toIso8601String().split('T')[0];
      final endString = endDate.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('${ApiConfig.attendanceUrl}?start_date=$startString&end_date=$endString'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar presenças: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar presenças: $e');
    }
  }

  static Future<AttendanceRecord> createOrUpdateAttendance(AttendanceRecord record) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.attendanceUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(record.toCreateJson()),
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AttendanceRecord.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erro ao criar/atualizar presença: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar/atualizar presença: $e');
    }
  }

  static Future<AttendanceRecord> updateAttendance(int id, AttendanceRecord record) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.attendanceUrl}/$id'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(record.toUpdateJson()),
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        return AttendanceRecord.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erro ao atualizar presença: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar presença: $e');
    }
  }

  static Future<void> deleteAttendance(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.attendanceUrl}/$id'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar presença: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao deletar presença: $e');
    }
  }

  static Future<List<AttendanceRecord>> getConsulenteAttendanceHistory(int consulenteId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.attendanceUrl}/consulente/$consulenteId'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> recordsJson = jsonData['records'];
        return recordsJson.map((json) => AttendanceRecord.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar histórico de presenças: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar histórico de presenças: $e');
    }
  }

  static Future<Map<String, int>> getAttendanceStats(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${ApiConfig.attendanceUrl}/stats/$dateString'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return {
          'total_records': jsonData['total_records'] ?? 0,
          'presentes': jsonData['presentes'] ?? 0,
          'faltas': jsonData['faltas'] ?? 0,
          'pendentes': jsonData['pendentes'] ?? 0,
        };
      } else {
        throw Exception('Erro ao buscar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas: $e');
    }
  }

  static Future<List<Consulente>> getAllConsulentes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.consulentesUrl),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Consulente.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar consulentes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar consulentes: $e');
    }
  }

  static Future<List<ConsulenteSession>> getSessionsWithAcompanhantesByDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${ApiConfig.consulentesUrl}/sessions-by-date/$dateString'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ConsulenteSession.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar sessões: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar sessões: $e');
    }
  }

  static Future<List<AttendanceRecord>> createBulkAttendance(DateTime date, List<int> consulenteIds) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await http.post(
        Uri.parse('${ApiConfig.attendanceUrl}/bulk'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'attendance_date': dateString,
          'consulente_ids': consulenteIds,
        }),
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        // Buscar os registos criados
        return await getAttendanceByDate(date);
      } else {
        throw Exception('Erro ao criar presenças em massa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao criar presenças em massa: $e');
    }
  }

  static Future<List<Consulente>> getConsulentesWithoutAttendance(DateTime date) async {
    try {
      // Primeiro, buscar todos os consulentes
      final response = await http.get(
        Uri.parse(ApiConfig.consulentesUrl),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> allConsulentesJson = json.decode(response.body);
        final List<Consulente> allConsulentes = allConsulentesJson
            .map((json) => Consulente.fromJson(json))
            .toList();

        // Buscar presenças do dia
        final List<AttendanceRecord> attendanceRecords = await getAttendanceByDate(date);
        final Set<int> consulentesWithAttendance = attendanceRecords
            .map((record) => record.consulenteId)
            .toSet();

        // Filtrar consulentes sem presença registada
        return allConsulentes
            .where((consulente) => !consulentesWithAttendance.contains(consulente.id))
            .toList();
      } else {
        throw Exception('Erro ao buscar consulentes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar consulentes sem presença: $e');
    }
  }
}

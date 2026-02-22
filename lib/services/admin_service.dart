import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class AdminService {
  // Realizar reset completo do sistema
  Future<bool> resetSystem(String pin) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.adminUrl}/reset'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode({'pin': pin}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(data['error'] ?? 'Erro ao resetar o sistema');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro de conexão: $e');
    }
  }
}

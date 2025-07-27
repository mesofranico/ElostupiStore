import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../core/api_config.dart';

class PaymentService {

  // Buscar todos os pagamentos
  static Future<List<Payment>> getAllPayments() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.paymentsUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar pagamentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar pagamentos por membro
  static Future<List<Payment>> getPaymentsByMember(int memberId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.paymentsUrl}/member/$memberId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar pagamentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Criar novo pagamento
  static Future<Payment> createPayment(Payment payment) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.paymentsUrl),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(payment.toJson()),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Payment.fromJson(data);
      } else {
        throw Exception('Falha ao criar pagamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar pagamento
  static Future<Payment> updatePayment(Payment payment) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.paymentsUrl}/${payment.id}'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(payment.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Payment.fromJson(data);
      } else {
        throw Exception('Falha ao atualizar pagamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Deletar pagamento
  static Future<void> deletePayment(int id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.paymentsUrl}/$id'));
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao deletar pagamento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar pagamentos por período
  static Future<List<Payment>> getPaymentsByPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.paymentsUrl}/period?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar pagamentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Buscar pagamentos por status
  static Future<List<Payment>> getPaymentsByStatus(String status) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.paymentsUrl}/status/$status'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar pagamentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Obter relatório de pagamentos
  static Future<Map<String, dynamic>> getPaymentReport(DateTime startDate, DateTime endDate) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.paymentsUrl}/report?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Falha ao carregar relatório: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
} 
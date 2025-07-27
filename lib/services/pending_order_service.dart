import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PendingOrderService {
  static const String baseUrl = 'https://elostupi.pt/api/pending-orders';

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erro ao buscar pedidos pendentes');
    }
  }

  Future<bool> createPendingOrder(Map<String, dynamic> order) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(order),
    );
    if (kDebugMode) {
      if (kDebugMode) {
        print('[API] POST $baseUrl');
      }
    }
    if (kDebugMode) {
      print('[API] Status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('[API] Body: ${response.body}');
    }
    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Erro ao criar pedido pendente: ${response.statusCode} - ${response.body}');
    }
  }

  Future<bool> removePendingOrder(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    return response.statusCode == 200;
  }

  Future<bool> finalizePendingOrder(String id) async {
    final response = await http.post(Uri.parse('$baseUrl/$id/finalize'));
    return response.statusCode == 200;
  }
} 
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class DatabaseService {
  // Configuração da API
  static const String baseUrl = 'https://api.elostupi.pt/api';
  
  // Endpoints
  static const String productsEndpoint = '/products';
  static const String updateStockEndpoint = '/products/stock';
  static const String ordersEndpoint = '/orders';

  // Headers para autenticação (se necessário)
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer $token', // Se precisar de autenticação
  };

  // Buscar todos os produtos
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$productsEndpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseProducts(response.body);
      } else {
        throw Exception('Erro ao carregar produtos: Status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // Atualizar stock de um produto
  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$updateStockEndpoint/$productId'),
        headers: _headers,
        body: json.encode({
          'stock': newStock,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar stock: $e');
    }
  }

  // Decrementar stock após venda
  Future<Map<String, dynamic>> decrementStock(String productId, int quantity) async {
    try {
      if (kDebugMode) {
        print('[DEBUG] Requisição decrementStock para produto $productId, quantidade $quantity');
      }
      final response = await http.post(
        Uri.parse('$baseUrl$productsEndpoint/$productId/decrement'),
        headers: _headers,
        body: json.encode({
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        print('[DEBUG] Status:  [33m [1m${response.statusCode} [0m');
      }
      if (kDebugMode) {
        print('[DEBUG] Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return {'success': true, 'message': null};
      } else {
        String? msg;
        try {
          final jsonData = json.decode(response.body);
          msg = jsonData['error']?.toString() ?? response.body;
        } catch (_) {
          msg = response.body;
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] Erro decrementStock: $e');
      }
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Criar pedido
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$ordersEndpoint'),
        headers: _headers,
        body: json.encode(orderData),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar pedido: $e');
    }
  }

  // Buscar produto específico
  Future<Product?> getProduct(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$productsEndpoint/$productId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Product.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Erro ao buscar produto: $e');
    }
  }

  // Criar novo produto
  Future<bool> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$productsEndpoint'),
        headers: _headers,
        body: json.encode(product.toJson()),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar produto: $e');
    }
  }

  // Atualizar produto
  Future<bool> updateProduct(Product product) async {
    try {
      if (kDebugMode) {
        print('[DB] Atualizando produto: ${product.id}');
      }
      final response = await http.put(
        Uri.parse('$baseUrl$productsEndpoint/${product.id}'),
        headers: _headers,
        body: json.encode(product.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('[DB] Status da resposta: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('[DB] Body da resposta: ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('[DB] Erro ao atualizar produto: $e');
      }
      throw Exception('Erro ao atualizar produto: $e');
    }
  }

  // Deletar produto
  Future<bool> deleteProduct(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$productsEndpoint/$productId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao deletar produto: $e');
    }
  }

  // Parse dos produtos
  List<Product> _parseProducts(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao processar dados JSON: $e');
    }
  }
} 
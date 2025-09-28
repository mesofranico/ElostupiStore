import '../models/product.dart';
import 'database_service.dart';
import '../core/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Product>> getProducts() async {
    return await _databaseService.getProducts();
  }

  Future<bool> updateProductStock(String productId, int newStock) async {
    return await _databaseService.updateProductStock(productId, newStock);
  }

  Future<Map<String, dynamic>> decrementStock(String productId, int quantity) async {
    return await _databaseService.decrementStock(productId, quantity);
  }

  Future<Product?> getProduct(String productId) async {
    return await _databaseService.getProduct(productId);
  }

  Future<bool> createProduct(Product product) async {
    return await _databaseService.createProduct(product);
  }

  Future<bool> updateProduct(Product product) async {
    return await _databaseService.updateProduct(product);
  }

  Future<bool> deleteProduct(String productId) async {
    return await _databaseService.deleteProduct(productId);
  }

    // Métodos para gerir ordem das categorias
  Future<List<String>> getCategoryOrder() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/categories/order'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Erro ao carregar ordem das categorias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<List<String>> syncCategories() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/categories/sync'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return List<String>.from(data['categories'] ?? []);
      } else {
        throw Exception('Erro ao sincronizar categorias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  Future<void> updateCategoryOrder(List<String> categories) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/categories/order'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'categories': categories}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Erro ao atualizar ordem das categorias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
} 
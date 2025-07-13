import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  static const String primaryUrl = 'https://elostupi.pt/store/products.json';

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse(primaryUrl))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return _parseProducts(response.body);
      }
      
      throw Exception('Falha ao carregar produtos: Status ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  List<Product> _parseProducts(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao processar dados JSON: $e');
    }
  }
} 
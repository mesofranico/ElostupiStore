import '../models/product.dart';
import 'database_service.dart';

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
} 
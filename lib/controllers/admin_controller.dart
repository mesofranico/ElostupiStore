import 'package:get/get.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class AdminController extends GetxController {
  final ProductService _productService = ProductService();
  
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;

  // Criar novo produto
  Future<bool> createProduct(Product product) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      final success = await _productService.createProduct(product);
      if (success) {
        successMessage.value = 'Produto criado com sucesso!';
        return true;
      } else {
        errorMessage.value = 'Erro ao criar produto';
        return false;
      }
    } catch (e) {
      errorMessage.value = _getFriendlyErrorMessage(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Atualizar produto
  Future<bool> updateProduct(Product product) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      final success = await _productService.updateProduct(product);
      if (success) {
        successMessage.value = 'Produto atualizado com sucesso!';
        return true;
      } else {
        errorMessage.value = 'Erro ao atualizar produto';
        return false;
      }
    } catch (e) {
      errorMessage.value = _getFriendlyErrorMessage(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Deletar produto
  Future<bool> deleteProduct(String productId) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      final success = await _productService.deleteProduct(productId);
      if (success) {
        successMessage.value = 'Produto deletado com sucesso!';
        return true;
      } else {
        errorMessage.value = 'Erro ao deletar produto';
        return false;
      }
    } catch (e) {
      errorMessage.value = _getFriendlyErrorMessage(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Buscar produto por ID
  Future<Product?> getProduct(String productId) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final product = await _productService.getProduct(productId);
      return product;
    } catch (e) {
      errorMessage.value = _getFriendlyErrorMessage(e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Limpar mensagens
  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('SocketException') || error.contains('NetworkException')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    } else if (error.contains('TimeoutException')) {
      return 'Tempo limite excedido. A conexão está lenta, tente novamente.';
    } else if (error.contains('404') || error.contains('Not Found')) {
      return 'Produto não encontrado no servidor.';
    } else if (error.contains('400') || error.contains('Bad Request')) {
      return 'Dados inválidos. Verifique as informações do produto.';
    } else if (error.contains('500') || error.contains('Internal Server Error')) {
      return 'Erro no servidor. Tente novamente em alguns minutos.';
    } else {
      return 'Não foi possível processar a operação. Tente novamente.';
    }
  }
} 
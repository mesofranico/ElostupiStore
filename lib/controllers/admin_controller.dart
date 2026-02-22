import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/admin_service.dart';
import 'recado_controller.dart';
import 'attendance_controller.dart';
import 'member_controller.dart';
import 'product_controller.dart';
import 'consulente_controller.dart';
import 'finance_controller.dart';

class AdminController extends GetxController {
  final ProductService _productService = ProductService();
  final AdminService _adminService = AdminService();

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

  // Realizar reset completo do sistema
  Future<bool> resetSystem(String pin) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final success = await _adminService.resetSystem(pin);
      if (success) {
        successMessage.value = 'Sistema resetado com sucesso!';
        return true;
      } else {
        errorMessage.value = 'Erro ao resetar o sistema';
        return false;
      }
    } catch (e) {
      errorMessage.value = _getFriendlyErrorMessage(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Atualizar todos os controladores após um reset
  Future<void> refreshAllControllers() async {
    try {
      // Refresh MemberController
      try {
        final memberController = Get.find<MemberController>();
        await memberController.refreshData();
      } catch (_) {}

      // Refresh ConsulentesController
      try {
        final consulenteController = Get.find<ConsulentesController>();
        await consulenteController.refreshData();
      } catch (_) {}

      // Refresh ProductController
      try {
        final productController = Get.find<ProductController>();
        await productController.refreshData();
      } catch (_) {}

      // Refresh AttendanceController
      try {
        final attendanceController = Get.find<AttendanceController>();
        await attendanceController.refreshData();
      } catch (_) {}

      // Refresh RecadoController
      try {
        final recadoController = Get.find<RecadoController>();
        await recadoController.refreshData();
      } catch (_) {}

      // Refresh FinanceController
      try {
        final financeController = Get.find<FinanceController>();
        await financeController.loadAllData();
      } catch (_) {}
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar controladores: $e');
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('SocketException') ||
        error.contains('NetworkException')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    } else if (error.contains('TimeoutException')) {
      return 'Tempo limite excedido. A conexão está lenta, tente novamente.';
    } else if (error.contains('404') || error.contains('Not Found')) {
      return 'Produto não encontrado no servidor.';
    } else if (error.contains('400') || error.contains('Bad Request')) {
      return 'Dados inválidos. Verifique as informações do produto.';
    } else if (error.contains('500') ||
        error.contains('Internal Server Error')) {
      return 'Erro no servidor. Tente novamente em alguns minutos.';
    } else {
      return 'Não foi possível processar a operação. Tente novamente.';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/recado.dart';
import '../services/recado_service.dart';
import '../core/utils/ui_utils.dart';

class RecadoController extends GetxController {
  final RxList<Recado> recados = <Recado>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecados();
  }

  Future<void> loadRecados() async {
    try {
      isLoading.value = true;
      final list = await RecadoService.getAll();
      recados.assignAll(list);
    } catch (e) {
      // Erro silencioso ou log
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> add(Recado recado) async {
    try {
      UiUtils.showLoadingOverlay(message: 'A guardar recado...');
      final newRecado = await RecadoService.add(recado);
      recados.add(newRecado);
      UiUtils.hideLoading();
      Get.back(); // Voltar da tela de formulário
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error adding recado: $e');
      }
      UiUtils.hideLoading();
      UiUtils.showError('Erro ao guardar recado: $e');
    }
  }

  Future<void> updateRecado(Recado recado) async {
    try {
      UiUtils.showLoadingOverlay(message: 'A atualizar recado...');
      final updated = await RecadoService.update(recado);
      final i = recados.indexWhere((r) => r.id == updated.id);
      if (i >= 0) {
        recados[i] = updated;
      }
      UiUtils.hideLoading();
      Get.back(); // Voltar da tela de formulário
    } catch (e) {
      UiUtils.hideLoading();
      UiUtils.showError('Erro ao atualizar recado: $e');
    }
  }

  Future<void> remove(String id) async {
    try {
      UiUtils.showLoadingOverlay(message: 'A eliminar recado...');
      await RecadoService.delete(id);
      recados.removeWhere((r) => r.id == id);
      UiUtils.hideLoading();
    } catch (e) {
      UiUtils.hideLoading();
      UiUtils.showError('Erro ao eliminar recado: $e');
    }
  }

  Future<void> refreshData() async {
    recados.clear();
    try {
      final storage = GetStorage();
      await storage.remove('recados_cache');
      await storage.remove('cached_recados');
      await storage.remove('recados'); // Legacy key if any
    } catch (_) {}
    await loadRecados();
  }

  List<Recado> get comAlerta => recados
      .where(
        (r) => r.alerta || (r.diasRestantes != null && r.diasRestantes! <= 7),
      )
      .toList();
}

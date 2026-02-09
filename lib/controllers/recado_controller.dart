import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/recado.dart';

class RecadoController extends GetxController {
  final RxList<Recado> recados = <Recado>[].obs;
  static const String _storageKey = 'recados';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void _load() {
    try {
      final box = GetStorage();
      final list = box.read<List>(_storageKey);
      if (list != null) {
        recados.assignAll(
          list.map((e) => Recado.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        );
      }
    } catch (_) {
      recados.clear();
    }
  }

  Future<void> _save() async {
    final box = GetStorage();
    await box.write(_storageKey, recados.map((e) => e.toJson()).toList());
  }

  Future<void> add(Recado recado) async {
    recados.add(recado);
    await _save();
  }

  Future<void> updateRecado(Recado recado) async {
    final i = recados.indexWhere((r) => r.id == recado.id);
    if (i >= 0) {
      recados[i] = recado;
      await _save();
    }
  }

  Future<void> remove(String id) async {
    recados.removeWhere((r) => r.id == id);
    await _save();
  }

  List<Recado> get comAlerta => recados.where((r) => r.alerta || (r.diasRestantes != null && r.diasRestantes! <= 7)).toList();
}

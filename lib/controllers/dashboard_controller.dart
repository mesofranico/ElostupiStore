import 'package:get/get.dart';
import '../models/electricity_reading.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../services/electricity_service.dart';
import 'cart_controller.dart';
import 'product_controller.dart';

class DashboardController extends GetxController {
  final RxList<Member> overdueMembers = <Member>[].obs;
  final Rx<ElectricityReading?> lastReading = Rx<ElectricityReading?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final cartController = Get.find<CartController>();
      await cartController.updatePendingOrders();
    } catch (_) {}
    try {
      final list = await MemberService.getOverdueMembers();
      overdueMembers.assignAll(list);
    } catch (_) {
      overdueMembers.clear();
    }
    try {
      Get.find<ProductController>().products.refresh();
    } catch (_) {}
    try {
      final list = await ElectricityService.getAllReadings();
      list.sort((a, b) => b.readingDate.compareTo(a.readingDate));
      lastReading.value = list.isNotEmpty ? list.first : null;
    } catch (_) {
      lastReading.value = null;
    }
    isLoading.value = false;
  }
}

import 'package:get/get.dart';
import '../../controllers/member_controller.dart';
import '../../controllers/payment_controller.dart';

class MembershipBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MemberController>(() => MemberController());
    Get.lazyPut<PaymentController>(() => PaymentController());
  }
}

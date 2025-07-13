import 'package:get_storage/get_storage.dart';

class StorageInit {
  static Future<void> init() async {
    await GetStorage.init();
  }
} 
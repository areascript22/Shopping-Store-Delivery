import 'package:get/get.dart';
import 'package:google_maps_taxi_driver/controllers/network_controller.dart';

class DependencyInjection {
  static void init() {
    Get.put<NetworkController>(NetworkController(), permanent: true);
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:logger/logger.dart';

class NetworkController extends GetxController {
  final Logger logger = Logger();
  final Connectivity connectivity = Connectivity();
  var isConnecterToInternet = true.obs;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    connectivity.onConnectivityChanged.listen(_listenToConnectionChanged);
  }

  void _listenToConnectionChanged(List<ConnectivityResult> results) {
    // Check if any of the results indicate no internet connection
    bool hasNoInternet =
        results.any((result) => result == ConnectivityResult.none);
    isConnecterToInternet.value = !hasNoInternet;

    if (hasNoInternet) {
      // No internet connection
      Get.rawSnackbar(
        messageText: const Text(
          "POR FAVOR, CONECTESE A INTERNET PARA CONTINUAR",
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        isDismissible: false,
        duration: const Duration(days: 1),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[400]!,
        icon: const Icon(
          Icons.wifi_off,
          color: Colors.white,
          size: 35,
        ),
        margin: EdgeInsets.zero,
        snackStyle: SnackStyle.GROUNDED,
      );
    } else {
      // Internet connection available
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    }
  }
}

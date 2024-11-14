import 'package:google_maps_taxi_driver/models/driver.dart';

class FirestoreService {
  //Get the driver's data
  Future<Driver?> getCurrentDriverData() async {
    return await Driver.getCurrentDriverData();
  }

  //Get Driver Data with Retry mechanism
  Future<Driver?> getCurrentDriverDataWithRetry() async {
    return await Driver.getCurrentDriverDataWithRetry();
  }
}

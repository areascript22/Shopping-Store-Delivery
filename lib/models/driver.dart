import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';

class Driver {
  final String id;
  final String name;
  final String profileImage;
  final String email;
  final String phone;
  final double rating;
  final String vehicleModel;

  Driver({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.email,
    required this.phone,
    required this.rating,
    required this.vehicleModel,
  });
  factory Driver.fromDocument(DocumentSnapshot doc, String uId) => Driver(
        id: uId,
        name: doc['name'],
        phone: doc['phone'],
        profileImage: doc['profileImage'],
        email: doc['email'],
        rating: doc['rating'].toDouble(),
        vehicleModel: doc['vehicleModel'],
      );

  //Get the current driver's data
  static Future<Driver?> getCurrentDriverData() async {
    final Logger logger = Logger();
    String? uId = FirebaseAuth.instance.currentUser?.uid;
    if (uId == null) {
      return null;
    }
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('drivers').doc(uId).get();
      if (userDoc.exists) {
        return Driver.fromDocument(userDoc, uId);
      } else {
        logger.e("Driver data not found");
        return null;
      }
    } catch (e) {
      logger.e("Error trying to get driver data: $e");
      return null;
    }
  }

  //Get the current Driver's data with Retry Mechanism
static Future<Driver?> getCurrentDriverDataWithRetry() async {
  final Logger logger = Logger();
  String? uId = FirebaseAuth.instance.currentUser?.uid;
  if (uId == null) {
    return null;
  }

  const r =   RetryOptions(
    maxAttempts: 3,  // Maximum number of retries
    delayFactor:  Duration(seconds: 2),  // Exponential backoff delay factor
  );

  try {
    DocumentSnapshot userDoc = await r.retry(
      // The operation to retry
      () => FirebaseFirestore.instance.collection('drivers').doc(uId).get(),
      
      // Condition for retrying (e.g., transient network issues)
      retryIf: (e) {
        logger.e("Error trying to get driver data: $e");
        return e is FirebaseException && e.code == 'unavailable';
      },
    );

    if (userDoc.exists) {
      return Driver.fromDocument(userDoc, uId);
    } else {
      logger.e("Driver data not found");
      return null;
    }
  } catch (e) {
    logger.e("Failed to get driver data after retries: $e");
    return null;
  }
}

}

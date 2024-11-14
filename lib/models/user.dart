import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

//User: Who is rereuqesting the taxi
class User {
  final String id;
  final String name;
  final String lastName;
  final String profileImage;
  final String email;
  final String phoneNumber;
  final double rating;
  final int totalTrips;

  User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.profileImage,
    required this.email,
    required this.phoneNumber,
    required this.rating,
    required this.totalTrips,
  });

  //To create a Client from Firebase document
  factory User.fromDocument(DocumentSnapshot doc, String uId) => User(
        id: uId,
        name: doc['name'],
        lastName: doc['lastname'],
        profileImage: doc['profileImage'],
        email: doc['email'],
        rating: doc['rating'].toDouble(),
        totalTrips: doc['totalTrips'],
        phoneNumber: doc['phoneNumber'],
      );

  //Get client data given id. if user exists it returns a Map otherwise returns null
  static Future<User?> getUserDataById(String uId) async {
    final Logger logger = Logger();
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uId).get();
      if (userDoc.exists) {
        return User.fromDocument(userDoc, uId);
      } else {
        logger.e("User data not found");
        return null;
      }
    } catch (e) {
      logger.e("Error trying to get user data $e, uid: $uId");
      return null;
    }
  }
}

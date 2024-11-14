import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class RealTimeDatabase {
  final DatabaseReference requestsRef =
      FirebaseDatabase.instance.ref('requests');

  Stream<QuerySnapshot> readDataStream() {
    final instance =
        FirebaseFirestore.instance.collection("requests").snapshots();

    return instance;
  }
}

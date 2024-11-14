import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:google_maps_taxi_driver/models/user.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:logger/logger.dart';

class ClientRequestPageController {
  final Logger logger = Logger();
  //Get user data from firestore by id
  Future<User?> getUserDataById(String uId) async {
    return await User.getUserDataById(uId);
  }

  //Add driver id to user request and listen when the driver id is removed
  Future<void> addDriverToRequest(String requestId, String driverId,
      BuildContext context, MapDataProvider provider) async {
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref('requests/$requestId/drivers/$driverId');

    provider.driverListener = databaseReference.onValue.listen((event) {
      if (!event.snapshot.exists) {
        //Add logic to handle when the driver is removed from request
        provider.animController?.stop();
        if (provider.isBottomSheetOpen) {
          if (context.mounted) {
            Navigator.pop(context);
          }

          provider.isBottomSheetOpen = false;
        }
        provider.cancelDriverListener();
      }
    });

    try {
      await databaseReference.set({
        'driverId': driverId,
        'status': 'waiting', //Status:waiting, confirmed, haveArrived, finished
        'distance': provider.routeInfoCurrentPickUp!.distance,
        'duration': provider.routeInfoCurrentPickUp!.duration,
        'currentCoordinates': provider.currentLocation != null
            ? '${provider.currentLocation!.latitude},${provider.currentLocation!.longitude}'
            : 'N/A',
        'timestamp': ServerValue.timestamp,
      });
      //Display map page in "operating" mode
      provider.isCarryingPassanger = true;
      provider.pageIndex = 1;

      //Remove polylines from pick-up to drop-off
      provider.fromPickUpToDropOff!.points.clear();

      //PENDING: Animate camera to current and pick-up coordinates

      //set provider.estimatedTime  value
      String numericPart =
          provider.routeInfoCurrentPickUp!.duration.split(' ')[0];
      double timeInMinutes = double.parse(numericPart);
      int timeInSeconds = (timeInMinutes * 60).toInt();
      provider.estimatedTime = timeInSeconds;

      //initialize Countdown timer
      provider.countDownTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        if (provider.estimatedTime > 0) {
          provider.estimatedTime--;
        } else {
          provider.countDownTimer.cancel();
        }
      });
      provider.customInfoWindowControllerPickUp.hideInfoWindow!();
      provider.customInfoWindowControllerDropOff.hideInfoWindow!();

      logger.f("The user has accepted us as their driver");
      //Listen for Status changes
      // DatabaseReference statusReference = FirebaseDatabase.instance
      //     .ref('requests/$requestId/drivers/$driverId/status');
      // provider.driverStatusListener = statusReference.onValue.listen((event) {
      //   if (event.snapshot.exists) {
      //     final String newStatus = event.snapshot.value as String;
      //     if (newStatus == "confirmed") {
      //       //The user has accepted us for the trip
      //       if (provider.isBottomSheetOpen) {
      //         if (context.mounted) {
      //           Navigator.pop(context);
      //           provider.isBottomSheetOpen = false;
      //         }
      //       }
      //       //Display map page in "operating" mode
      //       provider.isCarryingPassanger = true;
      //       provider.pageIndex = 1;

      //       //Remove polylines from pick-up to drop-off
      //       provider.fromPickUpToDropOff!.points.clear();

      //       //PENDING: Animate camera to current and pick-up coordinates

      //       //set provider.estimatedTime  value
      //       String numericPart =
      //           provider.routeInfoCurrentPickUp!.duration.split(' ')[0];
      //       double timeInMinutes = double.parse(numericPart);
      //       int timeInSeconds = (timeInMinutes * 60).toInt();
      //       provider.estimatedTime = timeInSeconds;

      //       //initialize Countdown timer
      //       provider.countDownTimer =
      //           Timer.periodic(const Duration(seconds: 1), (timer) {
      //         if (provider.estimatedTime > 0) {
      //           provider.estimatedTime--;
      //         } else {
      //           provider.countDownTimer.cancel();
      //         }
      //       });
      //       provider.customInfoWindowControllerPickUp.hideInfoWindow!();
      //       provider.customInfoWindowControllerDropOff.hideInfoWindow!();

      //       logger.f("The user has accepted us as their driver");
      //       //  provider.cancelDriverStatusListener();
      //     }
      //     if (newStatus == 'goingToDropOff') {
      //       provider.messageMap = 'El pasajero esta llegando';
      //     }
      //   }
      // });
      logger.i("Driver successfully added to user request.");
    } catch (error) {
      logger.e("Failed to add driver to user request: $error");
    }
  }

  //Update driver's current location within user request (database)
  Future<void> updateDriverCurrentLocation(
      String requestId, String driverId, MapDataProvider provider) async {
    try {
      final DatabaseReference databaseReference = FirebaseDatabase.instance
          .ref('requests/$requestId/drivers/$driverId');
      databaseReference.update({
        'currentCoordinates': provider.currentLocation != null
            ? '${provider.currentLocation!.latitude},${provider.currentLocation!.longitude}'
            : 'N/A',
      });
      logger.i("Driver's current location updated in database");
    } catch (e) {
      logger
          .i("Error trying to update the current location of the taxi driver");
    }
  }

  //Update Request status to 'pending'
  Future<void> updateRequestStatus(
      String requestId, String driverId, MapDataProvider provider) async {
    DatabaseReference statusReference =
        FirebaseDatabase.instance.ref('requests/$requestId');
    try {
      await statusReference.update({
        'status': 'pending',
      });
      logger.i("Driver status updated to 'confirmed'");
    } catch (e) {
      logger.e("Failed to update driver status: $e");
    }
  }

  //Change driver status
  Future<void> updateDriverStatus(
      String requestId, String driverId, String newStatus) async {
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref('requests/$requestId/drivers/$driverId');

    try {
      await databaseReference.update({
        'status': newStatus,
      });
      logger.i("Driver status successfully updated to $newStatus.");
    } catch (error) {
      logger.e("Failed to update driver status: $error");
      // Consider providing user feedback here
    }
  }

//Change user resquest Sattus
  Future<void> updateUserRequestStatus(
      String requestId, String newStatus) async {
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref('requests/$requestId');

    try {
      await databaseReference.update({
        'status': newStatus,
      });
      logger.i("User request status successfully updated to $newStatus.");
    } catch (error) {
      logger.e("Failed to update User request status: $error");
      // Consider providing user feedback here
    }
  }

  //Remove driver id
  Future<void> removeDriverIdFromRequest(
      String requestId, String driverId) async {
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref('requests/$requestId/drivers/$driverId');
    try {
      await databaseReference.remove().then((value) => {
            logger.i("Driver id succefully removed."),
          });
    } catch (e) {
      logger.e("Error: while removing driver from user request: $e");
    }
  }

  //Remove all drivers id except one
  Future<void> removeAllDriversExcept(
      String requestId, String driverIdToKeep) async {
    final DatabaseReference driversRef =
        FirebaseDatabase.instance.ref('requests/$requestId/drivers');

    try {
      // Get all the children under 'drivers'
      final DataSnapshot snapshot = await driversRef.get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> drivers =
            snapshot.value as Map<dynamic, dynamic>;

        // Iterate over all drivers
        drivers.forEach((key, value) async {
          if (key != driverIdToKeep) {
            // Remove the driver if it's not the one to keep
            await driversRef.child(key).remove();
          }
        });
        logger.i("All drivers except $driverIdToKeep have been removed.");
      } else {
        logger.w("No drivers found under request $requestId.");
      }
    } catch (error) {
      logger.e("Failed to remove drivers: $error");
    }
  }

//Increment the total user trips field by one
  Future<void> incrementUserTotalTrips(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      await firestore.collection('users').doc(userId).update(
        {
          'totalTrips': FieldValue.increment(1),
        },
      );
      logger.i('totalTrip field incremented successfully!');
    } catch (e) {
      logger.i('Error incrementing totalTrip: $e');
    }
  }

  //TEST: Functions to calculate rating starts
  Future<void> saveRating(double rating, String userId, String driverId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    // 1. Save the rating for the current driver in subcollection
    await firestore
        .collection('users')
        .doc(userId)
        .collection('ratings')
        .doc(driverId)
        .set({
      'rating': rating,
    });

    // 2. Update the user's total rating and rating count
    await _updateUserRating(rating, userId);
  }

  Future<void> _updateUserRating(double newRating, String userId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference userRef = firestore.collection('users').doc(userId);

    // Use Firestore transaction to ensure atomic updates
    try {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          double totalRatingScore =
              (userSnapshot.get('totalRatingScore') ?? 0.0).toDouble();
          int ratingCount = (userSnapshot.get('ratingCount') ?? 0).toInt();

          // Update the total rating score and increment rating count
          totalRatingScore += newRating;
          ratingCount += 1;

          // Calculate the new average rating
          double averageRating = totalRatingScore / ratingCount.toDouble();
          averageRating = double.parse(averageRating.toStringAsFixed(1));

          // Update the user's document with the new total rating and count
          transaction.update(userRef, {
            'totalRatingScore': totalRatingScore,
            'ratingCount': ratingCount,
            'rating': averageRating,
          });
        } else {
          // If the user document does not exist, initialize the fields
          transaction.set(userRef, {
            'totalRatingScore': newRating,
            'ratingCount': 1,
            'rating': newRating,
          });
        }
      });
      logger.i('New rating has been saved and average updated.');
    } catch (e) {
      logger.e("An error has ocurred while transaction: rating stars");
    }
  }
}

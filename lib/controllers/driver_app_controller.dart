// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/components/loading_overlay.dart';
import 'package:google_maps_taxi_driver/components/user_bar_info.dart';
import 'package:google_maps_taxi_driver/controllers/client_request_page_controller.dart';
import 'package:google_maps_taxi_driver/models/route_info.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:logger/logger.dart';

class DriverAppController {
  final String googleAPIKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final Logger logger = Logger();
  final ClientRequestPageController clientRequestPageController =
      ClientRequestPageController();

  //It returns a route as polylines (it is use to update polyline in Porvider)
  Future<RouteInfo?> getRoutePoints(LatLng start, LatLng end) async {
    logger.t("getRoutePoints method    1 ");
    if (googleAPIKey.isEmpty) {
      logger.e("ERROR: There is no Google Api Key available");
      return null;
    }

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> routePoints = [];
    logger.t("getRoutePoints method    2 ");
    try {
      // PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      //   googleAPIKey,
      //   PointLatLng(start.latitude, start.longitude),
      //   PointLatLng(end.latitude, end.longitude),
      //   travelMode: TravelMode.driving,
      // );
 //     PolylineResult result;
      try {
        PolylineResult result = await polylinePoints
            .getRouteBetweenCoordinates(
              googleAPIKey,
              PointLatLng(start.latitude, start.longitude),
              PointLatLng(end.latitude, end.longitude),
              travelMode: TravelMode.driving,
            )
            .timeout(const  Duration(seconds: 10));

        logger.t("getRoutePoints method    3 ");

        if (result.points.isNotEmpty) {
          result.points.forEach((PointLatLng point) {
            routePoints.add(LatLng(point.latitude, point.longitude));
          });
        }
        logger.t("getRoutePoints method    4 ");
        return RouteInfo(
          distance: result.distance!,
          duration: result.duration!,
          polylinePoints: routePoints,
        );
      } on TimeoutException catch (e) {
        logger.e("Timeout occurred: $e");
        return null;
      } on SocketException catch (e) {
        logger.e("Network issue: $e");
        return null;
      } catch (e) {
        logger.e("Unknown error: $e");
        return null;
      }

      // logger.t("getRoutePoints method    3 ");

      // if (result.points.isNotEmpty) {
      //   result.points.forEach((PointLatLng point) {
      //     routePoints.add(LatLng(point.latitude, point.longitude));
      //   });
      // }
      // logger.t("getRoutePoints method    4 ");
      // return RouteInfo(
      //   distance: result.distance!,
      //   duration: result.duration!,
      //   polylinePoints: routePoints,
      // );
    } catch (e) {
      logger.e('Error fetching route: $e');
      return null;
    }
  }

  //Animate a camera to a given point and map controller
  void animateCameraToPosition(
      LatLng point, Completer<GoogleMapController> mapController) async {
    GoogleMapController controller = await mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(point.latitude, point.longitude),
      zoom: 15,
      bearing: 0,
    )));
  }

  //BOTTOM SHEET: Waiting for client comfirmation
  Future<void> clientConfirmationBottomSheet(
      BuildContext context, MapDataProvider provider) async {
    provider.isBottomSheetOpen = true;
    // isBottomSheetOpen = true;
    showModalBottomSheet(
      context: context,
      enableDrag: false, // Prevents the sheet from being dragged
      useSafeArea: true, // Ensures content is shown within safe areas
      isScrollControlled:
          true, // Allows the bottom sheet to take up full height
      isDismissible: false, // Prevents closing the sheet when tapping outside
      backgroundColor:
          Colors.transparent, // Transparent background for the overlay
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Blocks the back button
          child: Stack(
            children: [
              //Background text
              GestureDetector(
                onTap: () {
                  // Prevent dismissal on tap outside the bottom sheet
                },
                child: Container(
                  color: Colors.black54, // Semi-transparent black overlay
                  child: const Stack(
                    children: [
                      // Positioned text on the overlay area
                      Positioned(
                        top: 100,
                        left: 20,
                        right: 20,
                        child: Text(
                          'Esperando confirmación del cliente, por favor espere..',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20), // Rounded top corners
                    ),
                  ),
                  child: const Column(
                    children: [
                      //User information
                      UserInfoBar(),
                    ],
                  ),
                ),
              ),
              //Linear bar indicator
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: provider.animController!,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: provider.animation!.value,
                      backgroundColor: Colors.white,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

//BOTTOM SHEET: Star rating
  void showStarRatingBottomSheet(
      MapDataProvider mapDataProvider, BuildContext context) {
    OverlayEntry? overlayEntry;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text(
                'Califique su viaje',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) async {
                  //Send rating star to database
                  //  Show the overlay
                  final overlay = Overlay.of(context);
                  overlayEntry = OverlayEntry(
                    builder: (context) => LoadingOverlay(),
                  );
                  overlay.insert(overlayEntry!);
                  await clientRequestPageController.saveRating(rating,
                      mapDataProvider.user!.id, mapDataProvider.driver!.id);
                  //  Hide the overlay
                  overlayEntry?.remove();
                  overlayEntry = null;
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Omitir',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

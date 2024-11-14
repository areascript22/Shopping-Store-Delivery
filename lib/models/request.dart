import 'package:google_maps_flutter/google_maps_flutter.dart';

class Request {
  final String requestKey;
  final LatLng pickUpCoordinates;
  final LatLng destinationCoordinates;
  final Map<String, dynamic> products;
  //final String pickUpLocation;
  // final String destinationLocation;
  // final String reference;
  // final String duration;
  // final String distance;

  Request({
    required this.requestKey,
    required this.pickUpCoordinates,
    required this.destinationCoordinates,
    required this.products,
    // required this.pickUpLocation,
    // required this.destinationLocation,
    // required this.reference,
    // required this.duration,
    // required this.distance,
  });
}

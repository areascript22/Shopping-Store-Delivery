import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/components/loading_overlay.dart';
import 'package:google_maps_taxi_driver/components/my_buttom.dart';
import 'package:google_maps_taxi_driver/controllers/client_request_page_controller.dart';
import 'package:google_maps_taxi_driver/controllers/driver_app_controller.dart';
import 'package:google_maps_taxi_driver/models/route_info.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:location/location.dart';
import 'package:logger/logger.dart';
import 'package:map_launcher/map_launcher.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class MapPageController {
  VoidCallback? updateUi;
  final Logger logger = Logger();
  final ClientRequestPageController clientRequestPageController =
      ClientRequestPageController();
  final VoidCallback showRatingStart;
  MapPageController({
    required this.showRatingStart,
  });

  final DriverAppController driverAppController = DriverAppController();
  final Location locationController = Location();
  StreamSubscription<LocationData>? locationListener;

  LocationData? locationData;
  Marker? customMarker;
  BitmapDescriptor? customIcon;

  // LatLng? currentLocation;
  LatLng? previousLocation;

//BOTTOM SHEET: It displays all available maps
  Future<void> showAllAvailableMaps(
      BuildContext context, MapDataProvider provider) async {
    //Get all maps installed
    final availableMaps = await MapLauncher.installedMaps;
    if (!context.mounted) {
      return;
    }
    //Determinate destination coordinate (pick-up or drop-off)
    late Coords destination;
    if (!provider.iHaveArrived) {
      destination = Coords(provider.request!.pickUpCoordinates.latitude,
          provider.request!.pickUpCoordinates.longitude);
    } else {
      destination = Coords(provider.request!.destinationCoordinates.latitude,
          provider.request!.destinationCoordinates.longitude);
    }
    //Show all map apps options
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              //title
              const SizedBox(height: 15),
              //List of available maps
              ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable internal scrolling
                itemCount: availableMaps
                    .length, // Adjust this number based on your data
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      availableMaps[index].showMarker(
                          coords: destination, title: "Destination");
                    },
                    leading: SvgPicture.asset(
                      availableMaps[index].icon, // Path to the SVG icon
                      width: 40.0,
                      height: 40.0,
                    ),
                    title: Text(
                        availableMaps[index].mapName), // Your item content here
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  //BOTTOM SHEET: Showed to comfirm "cancel" the current taxi trip
  void showCencelTripBottomSheet(
      MapDataProvider mapDataProvider, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //User info
                Text("${mapDataProvider.user!.name} lo esta esperando"),
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 30,
                  child: ClipOval(
                    child: mapDataProvider.user!.profileImage.isEmpty
                        ? const Icon(Icons.person,
                            color: Color.fromARGB(255, 64, 58, 58), size: 24.0)
                        : FadeInImage.assetNetwork(
                            width: 100,
                            height: 100,
                            placeholder: 'assets/img/default_profile.png',
                            image: mapDataProvider.user!.profileImage,
                          ),
                  ),
                ),
                const Text("¿Está seguro de que quiere cancelar?"),
                const SizedBox(height: 20),
                //Confirm Cancel buttons
                MyButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    text: const Text("NO")),
                const SizedBox(height: 10),
                MyButton(
                    onPressed: () async {
                      //Remove my id from request in Realtime Database
                      await clientRequestPageController
                          .removeDriverIdFromRequest(
                              mapDataProvider.request!.requestKey,
                              mapDataProvider.driver!.id);
                      //Change Request status to 'pending' again
                      await clientRequestPageController.updateRequestStatus(
                          mapDataProvider.request!.requestKey,
                          mapDataProvider.driver!.id,
                          mapDataProvider);
                      //Navigate to Client request page
                      mapDataProvider.isCarryingPassanger = false;
                      mapDataProvider.iHaveArrived = false;
                      mapDataProvider.pageIndex = 0;
                      mapDataProvider.countDownTimer.cancel();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    text: const Text("Sí, cencelar")),
              ],
            ),
          ),
        );
      },
    );
  }

  //BOTTOM SHEET: Confirmation to end the trip
  Future<void> confirmEndTripBottomSheet(
      MapDataProvider mapDataProvider, BuildContext context) async {
    OverlayEntry? overlayEntry;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              //title
              const SizedBox(height: 15),
              //List of available maps
              const Center(child: Text("¿Ha completado la solicitud?")),
              const SizedBox(height: 15),
              MyButton(
                  onPressed: () async {
                    final overlay = Overlay.of(context);
                    overlayEntry = OverlayEntry(
                      builder: (context) => LoadingOverlay(),
                    );
                    overlay.insert(overlayEntry!);

                    //Set the user request as "finished" in database
                    await clientRequestPageController.updateUserRequestStatus(
                      mapDataProvider.request!.requestKey,
                      "finished",
                    );
                    //Set the driver's status as "finished" in database
                    await clientRequestPageController.updateDriverStatus(
                        mapDataProvider.request!.requestKey,
                        mapDataProvider.driver!.id,
                        "finished");

                    //Increment user total trips field by one
                    await clientRequestPageController
                        .incrementUserTotalTrips(mapDataProvider.user!.id);
                    overlayEntry!.remove();
                    overlayEntry = null;
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                    //Navigate to client requests page
                    mapDataProvider.isCarryingPassanger = false;
                    mapDataProvider.iHaveArrived = false;
                    mapDataProvider.pageIndex = 0;
                    mapDataProvider.countDownTimer.cancel();

                    showRatingStart();
                  },
                  text: const Text("Sí")),
              const SizedBox(height: 15),
              MyButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: const Text("No")),
            ],
          ),
        );
      },
    );
  }

  //PERMISSIONS: Request gps permissions
  void fetchLocationAndGpsPermissions(MapDataProvider provider) async {
    logger.i("location   1 ");
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) {
        provider.isGpsPermissionsEnabled = false;
        return;
      }
    }
    logger.i("location   2 ");
    permissionGranted = await locationController.requestPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        provider.isGpsPermissionsEnabled = false;
        logger.i("location   3 ");
        return;
      }
    }
    logger.i("location   finished ");
    provider.isGpsPermissionsEnabled = true;
    try {
      provider.currentLocation = await getCurrentLocation();
    } catch (e) {
      logger.i("Error occurred while getting location: $e");
    }
    //At this point gps permissions are granted
    //Set our custom icon for our current position
    await setCustomIcon(provider);
    //Initilize our listener and stored for dispose of it later.

    locationListener =
        locationController.onLocationChanged.listen((event) async {
      provider.currentLocation = LatLng(event.latitude!, event.longitude!);

      previousLocation ??= provider.currentLocation;
      // Calculate the distance between previous and current location
      double distance = _calculateDistance(
        previousLocation!.latitude,
        previousLocation!.longitude,
        provider.currentLocation!.latitude,
        provider.currentLocation!.longitude,
      );
      // Update route only if the movement exceeds a threshold (e.g., 10 meters)
      if (distance > 0.01) {
        logger.i(
            "Location changed by listener: ${event.latitude!}, ${event.longitude!}");
        //Update the custom marker with current location
        if (customIcon != null) {
          _setCustomMarker(customIcon!, provider);
          updateUi!();
        }
        if (provider.request != null && provider.driver != null) {
          //Update my current location in User request (database)
          await clientRequestPageController.updateDriverCurrentLocation(
              provider.request!.requestKey, provider.driver!.id, provider);

          //REcalculate route
          if (!provider.isCarryingPassanger || !provider.iHaveArrived) {
            //REcalculate green route
            RouteInfo? pointsCurrentA =
                await driverAppController.getRoutePoints(
                    provider.currentLocation!,
                    provider.request!.pickUpCoordinates);
            provider.fromCurrentToPickUp = Polyline(
              polylineId:
                 const  PolylineId('Destination location'),
              points:
                  pointsCurrentA != null ? pointsCurrentA.polylinePoints : [],
              width: 5,
              color: Colors.green,
            );
          } else {
            //Recalculate blue route
            if (provider.fromCurrentToPickUp!.points.isNotEmpty) {
              provider.fromCurrentToPickUp!.points.clear();
            }
            RouteInfo? pointsAB = await driverAppController.getRoutePoints(
                provider.currentLocation!,
                provider.request!.destinationCoordinates);
            provider.fromPickUpToDropOff = Polyline(
              polylineId:
                  const PolylineId('pick up location'),
              points: pointsAB != null ? pointsAB.polylinePoints : [],
              width: 5,
              color: Colors.blue,
            );
          }
        }

        previousLocation = provider.currentLocation;
      }
    });

    logger.f("location fetched");
  }

//GEt current location
  Future<LatLng> getCurrentLocation() async {
    LocationData currentLocation = await locationController.getLocation();
    logger.e("LOcation accourancy: ${currentLocation.accuracy}");
    LatLng currentLocationPoint =
        LatLng(currentLocation.latitude!, currentLocation.longitude!);
    return currentLocationPoint;
  }

  //Set custom icon
  Future<void> setCustomIcon(MapDataProvider provider) async {
    try {
      BitmapDescriptor customIcon;
      final ByteData byteData = await rootBundle.load('assets/img/taxi.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
          byteData.buffer.asUint8List(),
          targetWidth: 110); // Resize the image here
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? resizedByteData =
          await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List resizedImageData = resizedByteData!.buffer.asUint8List();
      customIcon = BitmapDescriptor.fromBytes(resizedImageData);
      this.customIcon = customIcon;
      //PENDING: Convert this into an function
      _setCustomMarker(customIcon, provider);
      //updateUi!();
      logger.i("Custom icon set");
    } catch (e) {
      logger.e(
          "Error trying to set custom icon for current location point: $e, current location: ${provider.currentLocation}");
    }
  }

  void _setCustomMarker(BitmapDescriptor customIcon, MapDataProvider provider) {
    customMarker = Marker(
      markerId: const MarkerId("current_location"),
      position: provider.currentLocation!,
      infoWindow: const InfoWindow(
        title: 'Tu posición actual',
        // snippet: 'Marker Snippet',
      ),
      icon: customIcon,
      anchor: const Offset(0.5, 0.5),
    );
  }

  // Function to calculate distance between two points using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Earth's radius in km
    double latDiff = _toRadians(lat2 - lat1);
    double lonDiff = _toRadians(lon2 - lon1);

    double a = sin(latDiff / 2) * sin(latDiff / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(lonDiff / 2) *
            sin(lonDiff / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c; // Distance in km
  }

  // Helper to convert degrees to radians
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

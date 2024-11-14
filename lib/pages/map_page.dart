import 'dart:async';

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/components/custom_bottom_sheet.dart';
import 'package:google_maps_taxi_driver/components/my_buttom.dart';
import 'package:google_maps_taxi_driver/components/my_drawer.dart';
import 'package:google_maps_taxi_driver/controllers/client_request_page_controller.dart';
import 'package:google_maps_taxi_driver/controllers/driver_app_controller.dart';
import 'package:google_maps_taxi_driver/controllers/map_page_controller.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:google_maps_taxi_driver/utils/map_themes_util.dart';
import 'package:ionicons/ionicons.dart';
import 'package:location/location.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback showRatingStart;
  final DriverAppController driverAppController;
  const MapPage({
    super.key,
    required this.onTap,
    required this.showRatingStart,
    required this.driverAppController,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final logger = Logger();
  late MapPageController mapPageController;
  final ClientRequestPageController clientRequestPageController =
      ClientRequestPageController();
  late MapDataProvider providerToDispose;

  // final Location locationController = Location();
  LocationData? locationData;

  bool isMapLoaded = true;
  //Geocoding
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(-1.672743, -78.648503),
    zoom: 17,
  );
  String addressTemp = "";
  late LatLng addressLatLng = const LatLng(-1.672743, -78.648503);
  final TextEditingController referenceTextController = TextEditingController();
  final TextEditingController locationTextController = TextEditingController();
  LatLng currentAddress = const LatLng(-1.672743, -78.648503);

  //Flag bools
  bool acceptedRequest = true; // Write driver id in user request
  int estimatedTime = 330; //Seconds

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    mapPageController =
        MapPageController(showRatingStart: widget.showRatingStart);
    mapPageController.updateUi = () => setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //Request permissions: Location
      final mapDataProvider =
          Provider.of<MapDataProvider>(context, listen: false);
      mapPageController.fetchLocationAndGpsPermissions(mapDataProvider);
    });
  }

  //To handle dark and light theme for the Map
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    providerToDispose = Provider.of<MapDataProvider>(context, listen: false);
    // changeMapstyle();
  }

  //Change the map style
  void changeMapstyle() {
    final brightness = Theme.of(context).brightness;
    final mapStyle = brightness == Brightness.dark
        ? MapThemesUtil.aubergine
        : MapThemesUtil.light;
    if (Provider.of<MapDataProvider>(context, listen: false)
        .mapController
        .isCompleted) {
      Provider.of<MapDataProvider>(context, listen: false)
          .mapController
          .future
          .then((value) => {
                value.setMapStyle(mapStyle),
              });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose

    // Limpiar TextEditingControllers
    referenceTextController.dispose();
    locationTextController.dispose();
    // Limpiar el GoogleMapController
    providerToDispose.mapController.future.then((controller) {
      controller.dispose();
    });
    providerToDispose.mapController = Completer(); //Reset our Completer

    // Limpiar los controladores de las ventanas de información personalizadas
    providerToDispose.customInfoWindowControllerPickUp.dispose();
    providerToDispose.customInfoWindowControllerDropOff.dispose();

    mapPageController.locationListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapDataProvider = Provider.of<MapDataProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Ruta solicitada"),
        actions: [
          if (mapDataProvider.isCarryingPassanger)
            TextButton(
              onPressed: () {
                //Show bottom sheet to cancel trip
                mapPageController.showCencelTripBottomSheet(
                    mapDataProvider, context);
              },
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
      drawer: MyCustomDrawer(),
      body: Center(
        child: !isMapLoaded
            ? const CircularProgressIndicator()
            : Stack(
                alignment: Alignment.center,
                children: [
                  //Google map
                  GoogleMap(
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    mapType: MapType.normal,
                    markers: {
                      ...mapDataProvider.markers,
                      mapPageController.customMarker ??
                          const Marker(
                            markerId: MarkerId("Default marker"),
                            icon: BitmapDescriptor.defaultMarker,
                          )
                    },
                    //  polylines: mapDataProvider.polylines,
                    polylines: {
                      mapDataProvider.fromCurrentToPickUp ??
                          const Polyline(
                              polylineId:
                                  PolylineId("From current to Pick Up")),
                      mapDataProvider.fromPickUpToDropOff ??
                          const Polyline(
                              polylineId:
                                  PolylineId("From Pick up to Drop off"))
                    },
                    initialCameraPosition: initialCameraPosition,
                    onMapCreated: (GoogleMapController controller) async {
                      if (!mapDataProvider.mapController.isCompleted) {
                        logger.e("map controller  no  completado");
                        mapDataProvider.mapController.complete(controller);

                        // changeMapstyle();
                      } else {
                        logger.e("Map controller ya completado");
                      }
                    },
                    onCameraMove: (position) {
                      initialCameraPosition = position;
                      mapDataProvider
                          .customInfoWindowControllerPickUp.onCameraMove!();
                      mapDataProvider
                          .customInfoWindowControllerDropOff.onCameraMove!();
                    },
                    onCameraIdle: () async {
                      currentAddress = initialCameraPosition.target;
                      setState(() {});
                    },
                  ),

                  //Info windows
                  CustomInfoWindow(
                    controller:
                        mapDataProvider.customInfoWindowControllerPickUp,
                    height: 50,
                    width: 70,
                    offset: 40,
                  ),
                  CustomInfoWindow(
                    controller:
                        mapDataProvider.customInfoWindowControllerDropOff,
                    height: 50,
                    width: 70,
                    offset: 40,
                  ),

                  //Message: Getting user route
                  if (!mapDataProvider.gettingRoute)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        Text(
                            "Cargando ruta del usuario.. ${mapDataProvider.gettingRoute}")
                      ],
                    ),

                  //Timer countdown: The user has accepted this driver
                  if (mapDataProvider.isCarryingPassanger &&
                      !mapDataProvider.iHaveArrived)
                    Positioned(
                      top: 0,
                      child: Text(
                        formatTime(mapDataProvider.estimatedTime),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 45),
                      ),
                    ),
                  //MESSAGE: "El pasajero esta llegando"
                  if (mapDataProvider.iHaveArrived)
                    Positioned(
                        top: 0,
                        child: Text(
                          mapDataProvider.messageMap,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )),
                  //BUTTON: Current location
                  if (mapDataProvider.currentLocation != null)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: ElevatedButton(
                        onPressed: () async {
                          //Navigate to current location

                          widget.driverAppController.animateCameraToPosition(
                              mapDataProvider.currentLocation!,
                              mapDataProvider.mapController);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Icon(
                          Ionicons.navigate,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                  //Custom Bottom Sheet
                  if (mapDataProvider.user != null &&
                      mapDataProvider.gettingRoute)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: Column(
                        children: [
                          //Navigate button
                          if (mapDataProvider.isCarryingPassanger)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                MyButton(
                                    onPressed: () async =>
                                        mapPageController.showAllAvailableMaps(
                                            context, mapDataProvider),
                                    text: const Row(
                                      children: [
                                        Icon(Ionicons.navigate),
                                        Text("Navegar"),
                                      ],
                                    )),
                              ],
                            ),
                          //Bottom Sheet
                          CustomBottomSheet(
                            acceptTrip: widget.onTap,
                            currentLocation: mapDataProvider.currentLocation,
                            endTrip: () async {
                              await mapPageController.confirmEndTripBottomSheet(
                                  mapDataProvider, context);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  //Helper funtions for this page
  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/controllers/client_request_page_controller.dart';
import 'package:google_maps_taxi_driver/controllers/driver_app_controller.dart';
import 'package:google_maps_taxi_driver/controllers/map_page_controller.dart';
import 'package:google_maps_taxi_driver/models/driver.dart';
import 'package:google_maps_taxi_driver/models/route_info.dart';
import 'package:google_maps_taxi_driver/pages/client_request_page.dart';
import 'package:google_maps_taxi_driver/pages/map_page.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:google_maps_taxi_driver/services/firestore_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class DriverApp extends StatefulWidget {
  const DriverApp({super.key});
  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> with TickerProviderStateMixin {
  Logger logger = Logger();
  late MapPage _mapPage;
  final MapPageController mapPageController =
      MapPageController(showRatingStart: () {});
  final DriverAppController driverAppController = DriverAppController();
  final ClientRequestPageController clientRequestPageController =
      ClientRequestPageController();
  final FirestoreService firestoreService = FirestoreService();

//FUNCTIONS
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //Create our Map page
    _mapPage = MapPage(
      onTap: _showRequestScreen,
      showRatingStart: _showRatingStartBottomSheet,
      driverAppController: driverAppController,
    );
    final provider = Provider.of<MapDataProvider>(context, listen: false);
    initializeAnimController(provider);
    getDriverData();
  }

  //Get current driver's data
  void getDriverData() async {
    final provider = Provider.of<MapDataProvider>(context, listen: false);
    //  Driver? driver = await firestoreService.getCurrentDriverData();
    Driver? driver = await firestoreService.getCurrentDriverDataWithRetry();
    if (driver != null) {
      provider.driver = driver;
    }
  }

  void initializeAnimController(MapDataProvider provider) {
    //Initialize controller from 5 seconds
    provider.animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: provider.animDuration),
    );
    //Initialize animation
    provider.animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: provider.animController!, curve: Curves.linear),
    );

    //Add event listener
    provider.animController!.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        //Remove our ID from User request in firebase
        final MapDataProvider provider =
            Provider.of<MapDataProvider>(context, listen: false);
        if (provider.isBottomSheetOpen) {
          if (provider.request != null) {
            await clientRequestPageController.removeDriverIdFromRequest(
                provider.request!.requestKey, provider.driver!.id);
          }
          if (mounted) {
            Navigator.pop(context);
            provider.isBottomSheetOpen = false;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    //Clean the location listeners ()
    super.dispose();
  }

  //Display map page and handle user, request data logic
  void _showMapScreen(MapDataProvider provider) async {
    logger.f('phase 1');
    //Animate camera to pick up coordinates
    driverAppController.animateCameraToPosition(
      provider.request!.pickUpCoordinates,
      provider.mapController,
    );
    logger.f('phase 2');
    provider.gettingRoute = false;
    //GEt polylines from A to B
    logger.f(
        'Values ${provider.request!.pickUpCoordinates}  ,  ${provider.request!.destinationCoordinates}');
    RouteInfo? routeFromAB = await driverAppController.getRoutePoints(
      provider.request!.pickUpCoordinates,
      provider.request!.destinationCoordinates,
    );
    logger.f('phase 3');

    provider.fromPickUpToDropOff = Polyline(
      //polylineId: PolylineId(provider.request!.pickUpLocation.toString()),
      polylineId: const PolylineId('pick up location'),
      points: routeFromAB != null ? routeFromAB.polylinePoints : [],
      width: 5,
      color: Colors.blue,
    );
    //GEt polylines from Current location to B
    late LatLng currentLocation;
    if (provider.currentLocation == null) {
      logger.f('phase 3.5');
      currentLocation = await mapPageController.getCurrentLocation();
      logger.f('phase 3.7 Current Location: $currentLocation');
    } else {
      currentLocation = provider.currentLocation!;
    }
    logger.f('phase 4 Current Location: $currentLocation');

    RouteInfo? routeFromCurrentA = await driverAppController.getRoutePoints(
      currentLocation,
      provider.request!.pickUpCoordinates,
    );
    logger.f('phase 5');
    provider.fromCurrentToPickUp = Polyline(
      // polylineId: PolylineId(provider.request!.destinationLocation.toString()),
      polylineId: PolylineId('Destination'),
      points: routeFromCurrentA != null ? routeFromCurrentA.polylinePoints : [],
      width: 5,
      color: Colors.green,
    );
    provider.gettingRoute = true;
    //Update routes info in provider
    provider.routeInfoCurrentPickUp = routeFromCurrentA;
    provider.routeInfoPickUpDropOff = routeFromAB;
    logger.f('phase 6');
    //Load marker's info windows
    await loadCustomInfoWindow(provider);
    logger.f('phase 7');
  }

//Simply display request page
  void _showRequestScreen() async {
    //Show Bottom Sheet Whith user data
    final MapDataProvider provider =
        Provider.of<MapDataProvider>(context, listen: false);
    // initializeAnimController(provider);
    //  provider.user = null;
    //provider.request = null;
    provider.animController?.reset();
    provider.animController?.forward();
    //await driverAppController.clientConfirmationBottomSheet(context, provider);
  }

  //sHOW rating start bottom sheet
  void _showRatingStartBottomSheet() {
    final MapDataProvider provider =
        Provider.of<MapDataProvider>(context, listen: false);
    driverAppController.showStarRatingBottomSheet(provider, context);
  }

  @override
  Widget build(BuildContext context) {
    final MapDataProvider provider = Provider.of<MapDataProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(children: [
        //All pages dsiplayed
        IndexedStack(
          index: provider.pageIndex,
          children: [
            ClientRequestsPage(
              onTap: () => _showMapScreen(provider),
            ),
            _mapPage,
          ],
        ),
      ]),
    );
  }

  //Custom marker's info window
  Future<void> loadCustomInfoWindow(MapDataProvider provider) async {
    GoogleMapController tempController = await provider.mapController.future;

    provider.customInfoWindowControllerPickUp.googleMapController =
        tempController;
    provider.customInfoWindowControllerDropOff.googleMapController =
        tempController;

    // Automatically show info windows for both markers
    if (provider.routeInfoCurrentPickUp != null) {
      provider.customInfoWindowControllerPickUp.addInfoWindow!(
        _buildInfoWindowContent(
          provider.routeInfoCurrentPickUp!.distance,
          provider.routeInfoCurrentPickUp!.duration,
          Colors.green,
        ),
        provider.request!.pickUpCoordinates,
      );
    }
    if (provider.routeInfoPickUpDropOff != null) {
      provider.customInfoWindowControllerDropOff.addInfoWindow!(
        _buildInfoWindowContent(provider.routeInfoPickUpDropOff!.distance,
            provider.routeInfoPickUpDropOff!.duration, Colors.blue),
        provider.request!.destinationCoordinates,
      );
    }
  }

  //Format time from seconds to minutes
  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  //To show custom info window
  Widget _buildInfoWindowContent(
      String time, String distance, Color backgroudColor) {
    return Container(
      decoration: BoxDecoration(
        color: backgroudColor, // Background color
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            distance,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

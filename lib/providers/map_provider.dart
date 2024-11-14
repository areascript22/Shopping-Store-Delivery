import 'dart:async';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/models/driver.dart';
import 'package:google_maps_taxi_driver/models/route_info.dart';
import 'package:google_maps_taxi_driver/models/user.dart';
import 'package:google_maps_taxi_driver/models/request.dart';

class MapDataProvider extends ChangeNotifier {
  Request? _request;
  User? _user;
  Set<Marker> _markers = {};
  RouteInfo? routeInfoCurrentPickUp;
  RouteInfo? routeInfoPickUpDropOff;
  Polyline? _fromPickUpToDropOff;
  Polyline? _fromCurrentToPickUp;
  LatLng? currentLocation;
  bool _gettingRoute =
      false; //False: Calculating user route. True: User route calculated

   Completer<GoogleMapController> mapController = Completer();

  final CustomInfoWindowController customInfoWindowControllerPickUp =
      CustomInfoWindowController();
  final CustomInfoWindowController customInfoWindowControllerDropOff =
      CustomInfoWindowController();
  int _pageIndex = 0; //0:ClientRequestPage 1:MapPage

  //PAGE: DriverApp()
  bool _iHaveArrived = false; //True: I have reach the pick up location
  bool isCarryingPassanger = false; //True:I have accepted a trip
  bool isBottomSheetOpen = false;
  bool isGpsPermissionsEnabled = false;
  bool isConnectedToInternet = false; // To check whether or not there is an Internet connection
  String messageMap = '';
  //Timer and animations
  int _estimatedTime = 330; //Estamated time from two coordinates
  late Timer countDownTimer;
  AnimationController? animController;
  Animation<double>? animation;
  final int animDuration = 10;
  //To handle Listener canceling
  StreamSubscription<DatabaseEvent>? driverListener;
  StreamSubscription<DatabaseEvent>? driverStatusListener;
  // StreamSubscription<LocationData>? locationListener;

  //Driver data
  Driver? _driver;

  //GETTERS
  Request? get request => _request;
  User? get user => _user;
  Set<Marker> get markers => _markers;
  bool get gettingRoute => _gettingRoute;
  int get pageIndex => _pageIndex;
  bool get iHaveArrived => _iHaveArrived;
  Polyline? get fromCurrentToPickUp => _fromCurrentToPickUp;
  Polyline? get fromPickUpToDropOff => _fromPickUpToDropOff;
  int get estimatedTime => _estimatedTime;
  Driver? get driver => _driver;

  //SETTERS
  set request(Request? value) {
    _request = value;
    notifyListeners();
  }

  set user(User? value) {
    _user = value;
    notifyListeners();
  }

  set markers(Set<Marker> value) {
    _markers = value;
    notifyListeners();
  }

  set gettingRoute(bool value) {
    _gettingRoute = value;
    notifyListeners();
  }

  set pageIndex(int value) {
    _pageIndex = value;
    notifyListeners();
  }

  set iHaveArrived(bool value) {
    _iHaveArrived = value;
    notifyListeners();
  }

  set fromCurrentToPickUp(Polyline? value) {
    _fromCurrentToPickUp = value;
    notifyListeners();
  }

  set fromPickUpToDropOff(Polyline? value) {
    _fromPickUpToDropOff = value;
    notifyListeners();
  }

  set estimatedTime(int value) {
    _estimatedTime = value;
    notifyListeners();
  }

  set driver(Driver? value) {
    _driver = value;
    notifyListeners();
  }

  //Add a new marker
  void addMarker(LatLng position, String markerId, double hue) {
    markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: const InfoWindow(
          title: 'Marker Title',
          snippet: 'Marker Snippet',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ),
    );
    notifyListeners();
  }

  void cancelDriverListener() {
    driverListener?.cancel();
    driverListener = null;
  }

  void cancelDriverStatusListener() {
    driverStatusListener?.cancel();
    driverStatusListener = null;
  }

  //Add current location marker to the Markers set {}
  // void addCurrentLocationMarker(Marker marker) {
  //   markers.add(marker);
  //   notifyListeners();
  // }
}

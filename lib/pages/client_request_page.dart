import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_taxi_driver/components/my_drawer.dart';
import 'package:google_maps_taxi_driver/components/user_list_tile.dart';
import 'package:google_maps_taxi_driver/controllers/client_request_page_controller.dart';
import 'package:google_maps_taxi_driver/controllers/network_controller.dart';
import 'package:google_maps_taxi_driver/services/realtime_database.dart';
import 'package:google_maps_taxi_driver/models/user.dart';
import 'package:google_maps_taxi_driver/models/request.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class ClientRequestsPage extends StatefulWidget {
  final VoidCallback onTap;
  const ClientRequestsPage({
    super.key,
    required this.onTap,
  });

  @override
  State<ClientRequestsPage> createState() => _ClientRequestsPageState();
}

class _ClientRequestsPageState extends State<ClientRequestsPage> {
  final RealTimeDatabase _databaseReference = RealTimeDatabase();
  final ClientRequestPageController _clientRequestPageController =
      ClientRequestPageController();
  final Logger logger = Logger();
  final networkController = Get.find<NetworkController>();

  //herpers functions
  LatLng? stringToLatLng(String? str) {
    if (str == null) return null;
    // Split the string by comma
    final parts = str.split(',');

    // Parse latitude and longitude
    final double latitude = double.parse(parts[0]);
    final double longitude = double.parse(parts[1]);

    // Create and return LatLng object
    return LatLng(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    final mapDataProvider = Provider.of<MapDataProvider>(context);
    return Scaffold(
        appBar: AppBar(
          title: const Text("Solicitudes"),
        ),
        drawer: MyCustomDrawer(),
        body: Obx(
          () => networkController.isConnecterToInternet.value
              ? StreamBuilder(
                  stream: _databaseReference.requestsRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.none) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(snapshot.error.toString()),
                      );
                    }
                    if (snapshot.hasData &&
                        snapshot.data!.snapshot.value != null) {
                      //Build lists of client requests
                      Map<dynamic, dynamic> data = snapshot.data!.snapshot.value
                          as Map<dynamic, dynamic>;

                      List<MapEntry<dynamic, dynamic>> entriesRaw =
                          data.entries.toList();
                      List<MapEntry<dynamic, dynamic>> entriesToBuild = [];
                      //Filter only pending requests
                      entriesRaw.forEach((element) {
                        if (element.value['status'] == 'pending') {
                          entriesToBuild.add(element);
                        }
                      });
                      //If there is no "pending" requests
                      if (entriesToBuild.isEmpty) {
                        return const Center(
                            child: Text("NO hay solicitudes pendientes.."));
                      }
                      return ListView.builder(
                        itemCount: entriesToBuild.length,
                        itemBuilder: (context, index) {
                          //Get data raw from firebase
                          var firebaseRequest = entriesToBuild[index].value;
                          //get request key
                          final String requestKey = entriesToBuild[index].key;
                          //Request model
                          Request request = Request(
                              requestKey: requestKey,
                              pickUpCoordinates:
                                  stringToLatLng(firebaseRequest['pick_up']) ??
                                      const LatLng(0.0, 0.0),
                              destinationCoordinates:
                                  stringToLatLng(firebaseRequest['drop_off']) ??
                                      const LatLng(0.0, 0),
                              products: {});
                          //Get user data by id
                          //String userId = firebaseRequest['clientId'] ?? "N/A";
                          String userId = requestKey;

                          return FutureBuilder<User?>(
                            future: _clientRequestPageController
                                .getUserDataById(userId),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                    "An error has ocurred getting user data: ${snapshot.error}");
                              } else if (snapshot.hasData) {
                                //Get client data from firebase
                                User user = snapshot.data as User;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 1, horizontal: 10),
                                  child: UserListTile(
                                    onTap: widget.onTap,
                                    mapDataProvider: mapDataProvider,
                                    request: request,
                                    user: user,
                                    currentUserId: userId,
                                  ),
                                );
                              } else {
                                return const Text("No data available");
                              }
                            },
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text("No requests availables"),
                      );
                    }
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.red,
                  ),
                ),
        ));
  }
}

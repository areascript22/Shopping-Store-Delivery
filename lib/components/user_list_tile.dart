import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/controllers/map_page_controller.dart';
import 'package:google_maps_taxi_driver/models/user.dart';
import 'package:google_maps_taxi_driver/models/request.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:ionicons/ionicons.dart';

class UserListTile extends StatefulWidget {
  final MapDataProvider mapDataProvider;
  final Request request;
  final User user;
  final VoidCallback onTap;
  final String currentUserId;

  const UserListTile({
    super.key,
    required this.mapDataProvider,
    required this.request,
    required this.user,
    required this.onTap,
    required this.currentUserId,
  });

  @override
  State<UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<UserListTile> {
  String? pickUpLocation;
  String? dropOffLocation;
  final MapPageController mapPageController =
      MapPageController(showRatingStart: () {});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pickUpLocation = 'asdfsadfsadfsadf';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //Request permissions: Location
      pickUpLocation = await mapPageController
          .convertCoordsIntoLocation(widget.request.pickUpCoordinates);
      dropOffLocation = await mapPageController
          .convertCoordsIntoLocation(widget.request.destinationCoordinates);
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        widget.mapDataProvider.markers.clear();
        if (widget.mapDataProvider.fromCurrentToPickUp != null) {
          widget.mapDataProvider.fromCurrentToPickUp!.points.clear();
        }
        if (widget.mapDataProvider.fromPickUpToDropOff != null) {
          widget.mapDataProvider.fromPickUpToDropOff!.points.clear();
        }
        widget.mapDataProvider.addMarker(widget.request.pickUpCoordinates,
            "pick-up", BitmapDescriptor.hueGreen);
        widget.mapDataProvider.addMarker(widget.request.destinationCoordinates,
            "drop-off", BitmapDescriptor.hueAzure);
        //Show marker's info window

        widget.mapDataProvider.request = widget.request;
        widget.mapDataProvider.user = widget.user;
        widget.mapDataProvider.pageIndex = 1;
        widget
            .mapDataProvider.customInfoWindowControllerPickUp.hideInfoWindow!();
        widget.mapDataProvider.customInfoWindowControllerDropOff
            .hideInfoWindow!();

        widget.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: ClipOval(
                    child: widget.user.profileImage.isEmpty
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 24.0)
                        : FadeInImage.assetNetwork(
                            placeholder: 'assets/img/default_profile.png',
                            image: widget.user.profileImage,
                            fadeInDuration: const Duration(milliseconds: 50),
                            width: 100,
                            height: 100,
                          ),
                  ),
                ),
                Text(
                  widget.user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(
                      Ionicons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    if (widget.user.totalTrips >= 2)
                      Text(
                          "${widget.user.rating.toString()}(${widget.user.totalTrips})"),
                    if (widget.user.totalTrips < 2) const Text("Nuevo"),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickUpLocation != null ? pickUpLocation! : "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dropOffLocation != null ? dropOffLocation! : '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4.0),
                  // Row(
                  //   children: [
                  //     Text(
                  //       '~${request.distance}',
                  //       style: TextStyle(color: Colors.grey[600]),
                  //     ),
                  //     const SizedBox(width: 4.0),
                  //     Text(
                  //       '·',
                  //       style: TextStyle(color: Colors.grey[600]),
                  //     ),
                  //     const SizedBox(width: 4.0),
                  //     Text(
                  //       request.duration,
                  //       style: TextStyle(color: Colors.grey[600]),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

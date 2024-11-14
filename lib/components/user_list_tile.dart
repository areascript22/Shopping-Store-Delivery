import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/models/user.dart';
import 'package:google_maps_taxi_driver/models/request.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:ionicons/ionicons.dart';

class UserListTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        mapDataProvider.markers.clear();
        if (mapDataProvider.fromCurrentToPickUp != null) {
          mapDataProvider.fromCurrentToPickUp!.points.clear();
        }
        if (mapDataProvider.fromPickUpToDropOff != null) {
          mapDataProvider.fromPickUpToDropOff!.points.clear();
        }
        mapDataProvider.addMarker(
            request.pickUpCoordinates, "pick-up", BitmapDescriptor.hueGreen);
        mapDataProvider.addMarker(request.destinationCoordinates, "drop-off",
            BitmapDescriptor.hueAzure);
        //Show marker's info window

        mapDataProvider.request = request;
        mapDataProvider.user = user;
        mapDataProvider.pageIndex = 1;
        mapDataProvider.customInfoWindowControllerPickUp.hideInfoWindow!();
        mapDataProvider.customInfoWindowControllerDropOff.hideInfoWindow!();

        onTap();
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
                    child: user.profileImage.isEmpty
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 24.0)
                        : FadeInImage.assetNetwork(
                            placeholder: 'assets/img/default_profile.png',
                            image: user.profileImage,
                            fadeInDuration: const Duration(milliseconds: 50),
                            width: 100,
                            height: 100,
                          ),
                  ),
                ),
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(
                      Ionicons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    if (user.totalTrips >= 2)
                      Text("${user.rating.toString()}(${user.totalTrips})"),
                    if (user.totalTrips < 2) const Text("Nuevo"),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   request.pickUpLocation,
                  //   style: const TextStyle(fontWeight: FontWeight.bold),
                  // ),
                  // Text(
                  //   request.destinationLocation,
                  //   style: TextStyle(color: Colors.grey[600]),
                  // ),
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

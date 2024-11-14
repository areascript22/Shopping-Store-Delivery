import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_taxi_driver/components/buttons/themed_elavated_button.dart';
import 'package:google_maps_taxi_driver/components/my_buttom.dart';
import 'package:google_maps_taxi_driver/components/user_bar_info.dart';
import 'package:google_maps_taxi_driver/controllers/client_request_page_controller.dart';
import 'package:google_maps_taxi_driver/controllers/driver_app_controller.dart';
import 'package:google_maps_taxi_driver/models/route_info.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:provider/provider.dart';

class CustomBottomSheet extends StatefulWidget {
  final VoidCallback acceptTrip;
  final VoidCallback endTrip;
  final LatLng? currentLocation;
  const CustomBottomSheet({
    super.key,
    required this.acceptTrip,
    required this.endTrip,
    required this.currentLocation,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  final DriverAppController driverAppController = DriverAppController();
  final ClientRequestPageController clientRequestPageController =
      ClientRequestPageController();
  bool acceptedRequest = true;
  @override
  Widget build(BuildContext context) {
    final MapDataProvider mapDataProvider =
        Provider.of<MapDataProvider>(context);
    return
        //Navigation options Button

        //Bottom sheet
        Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
        child: Column(
          children: [
            //User information
            const UserInfoBar(),
            const SizedBox(height: 15),

            //BUTTON: I have arrived Button
            if (mapDataProvider.isCarryingPassanger &&
                !mapDataProvider.iHaveArrived)
              MyButton(
                onPressed: () async {
                  //Tha taxi driver has arriver to pick up location
                  await clientRequestPageController.updateDriverStatus(
                      mapDataProvider.request!.requestKey,
                      mapDataProvider.driver!.id,
                      "haveArrived");
                  mapDataProvider.iHaveArrived = true;
                  //Remove Pick Up marker
                  mapDataProvider.markers.removeWhere(
                      (element) => element.markerId.value == "pick-up");
                  //Clear blue route "fromCurrentToPickUp" polyline
                  mapDataProvider.fromCurrentToPickUp!.points.clear();
                  //Recalculate and draw route from current to drop off location
                  RouteInfo? pointsAB;
                  if (widget.currentLocation != null) {
                    pointsAB = await driverAppController.getRoutePoints(
                        widget.currentLocation!,
                        mapDataProvider.request!.destinationCoordinates);
                  }

                  mapDataProvider.fromPickUpToDropOff = Polyline(
                    polylineId: const PolylineId(
                        'pick up location'),
                    points: pointsAB != null ? pointsAB.polylinePoints : [],
                    width: 5,
                    color: Colors.blue,
                  );

                  //Update meesage
                  mapDataProvider.messageMap = 'Hemos notificado al cliente...';
                },
                text: const Text("He llegado",
                    style: TextStyle(color: Colors.white)),
              ),

            //BUTTON: End the trio
            if (mapDataProvider.isCarryingPassanger &&
                mapDataProvider.iHaveArrived)
              MyButton(
                onPressed: () {
                  //Logic to finalize the trip
                  widget.endTrip();
                },
                text: const Text("Finalizar el viaje",
                    style: TextStyle(color: Colors.white)),
              ),

            //Accept / Refuse Buttons
            if (!mapDataProvider.isCarryingPassanger)
              Column(
                children: [
                  MyButton(
                    onPressed: () async {
                      //Handle the request acceptance process
                      setState(() {
                        acceptedRequest = false;
                      });
                      await clientRequestPageController.addDriverToRequest(
                          mapDataProvider.request!.requestKey,
                          mapDataProvider.driver!.id,
                          context,
                          mapDataProvider);
                      setState(() {
                        acceptedRequest = true;
                      });
                      //Show ClienRequestPage()
                    //  mapDataProvider.pageIndex = 0;
                      widget.acceptTrip();
                    },
                    text: !acceptedRequest
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Aceptar viaje",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 8),
                  ThemedElevatedButton(
                    onTap: () {
                      mapDataProvider.pageIndex = 0;
                    },
                    child: const Text(
                      "Cerrar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            //Some Bottom space
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

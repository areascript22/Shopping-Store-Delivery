import 'package:flutter/material.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UserInfoBar extends StatelessWidget {
  const UserInfoBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MapDataProvider mapDataProvider =
        Provider.of<MapDataProvider>(context);

    if (mapDataProvider.user == null) {
      return const Text("No data available..");
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Porfile pic
        Container(
          decoration: const BoxDecoration(),
          child: Column(
            children: [
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
              Text(
                mapDataProvider.user!.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.yellow),
                  if (mapDataProvider.user!.totalTrips >= 2)
                    Text(
                        "${mapDataProvider.user!.rating.toString()}(${mapDataProvider.user!.totalTrips})"),
                  if (mapDataProvider.user!.totalTrips < 2) const Text("Nuevo"),
                ],
              ),
            ],
          ),
        ),
        //Locations pick-up and drop-off
        Expanded(
          child: Container(
            decoration: const BoxDecoration(),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Ionicons.location,
                          color: Colors.green,
                        ),
                        // Expanded(
                        //   child: Text(
                        //     mapDataProvider.request != null
                        //         ? mapDataProvider.request!.pickUpLocation
                        //         : "N/A",
                        //     maxLines: 1,
                        //     overflow: TextOverflow.ellipsis,
                        //     style: const TextStyle(fontWeight: FontWeight.bold),
                        //   ),
                        // ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Ionicons.location,
                          color: Colors.blue,
                        ),
                        // Expanded(
                        //   child: Text(
                        //     mapDataProvider.request != null
                        //         ? mapDataProvider.request!.destinationLocation
                        //         : "N/A",
                        //     maxLines: 1,
                        //     overflow: TextOverflow.ellipsis,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        //Comunication options (if it is in operation mode)
        if (mapDataProvider.isCarryingPassanger)
          Column(
            children: [
              IconButton(
                onPressed: () {
                  _sendSMS('+593967340047', 'I am on my way to pick you up!');
                },
                icon: const Icon(Ionicons.chatbox_ellipses_outline),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Ionicons.call_outline),
              ),
            ],
          ),
      ],
    );
  }

  // Function to send SMS
  void _sendSMS(String phoneNumber, String message) async {
    final Logger logger = Logger();
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    // Convert the URI to a string
    final String smsUrl = smsUri.toString();

    if (await canLaunch(smsUrl)) {
      await launch(smsUrl);
    } else {
      logger.e('Could not launch SMS: $smsUrl');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_taxi_driver/controllers/network_controller.dart';
import 'package:google_maps_taxi_driver/models/driver.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:google_maps_taxi_driver/services/auth_service.dart';
import 'package:google_maps_taxi_driver/utils/dialog_util.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';

class MyCustomDrawer extends StatelessWidget {
  final TextEditingController ipAddController = TextEditingController();
  final AuthService authService = AuthService();
  final networkController = Get.find<NetworkController>();
  MyCustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //User data banner
                const SizedBox(height: 50),
                Consumer<MapDataProvider>(
                  builder: (context, value, child) {
                    Driver? driverData = value.driver;
                    return driverData != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //Profile Image
                                  Obx(() => networkController
                                          .isConnecterToInternet.value
                                      ? CircleAvatar(
                                          radius: 35,
                                          backgroundColor: Colors.transparent,
                                          child: ClipOval(
                                            child: value.driver!.profileImage !=
                                                    ""
                                                ? FadeInImage.assetNetwork(
                                                    placeholder:
                                                        'assets/img/no_image.png',
                                                    image: value
                                                        .driver!.profileImage,
                                                    fadeInDuration:
                                                        const Duration(
                                                            milliseconds: 50),
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
                                                  )
                                                : Image.asset(
                                                    'assets/img/default_profile.png',
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
                                                  ),
                                          ),
                                        )
                                      : const CircularProgressIndicator(
                                          color: Colors.red,
                                        )),

                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        value.driver!.name,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Color(0xFFFDA503),
                                          ),
                                          Text(value.driver!.rating.toString())
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Ionicons.chevron_forward))
                            ],
                          )
                        : const CircularProgressIndicator();
                  },
                ),

                const SizedBox(height: 20),

                //COnfiguración
                ListTile(
                  leading: const Icon(Ionicons.settings),
                  title: const Text("Configuración"),
                  onTap: () {},
                ),
                //Trips history
                ListTile(
                  leading: const Icon(Ionicons.car),
                  title: const Text("Historial de viajes"),
                  onTap: () {},
                ),
                //Help for driver
                ListTile(
                  leading: const Icon(Ionicons.help),
                  title: const Text("Ayuda"),
                  onTap: () {},
                ),
              ],
            ),
            //Sing Out
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text("Cerrar sesion"),
                onTap: () {
                  DialogUtil.messageDialog(
                      context: context,
                      onAccept: () async {
                        //Clear anim controller
                        if (Provider.of<MapDataProvider>(context, listen: false)
                                .animController !=
                            null) {
                          Provider.of<MapDataProvider>(context, listen: false)
                              .animController!
                              .dispose();
                        }

                        final provider = Provider.of<MapDataProvider>(context,
                            listen: false);
                        provider.cancelDriverListener();
                        provider.cancelDriverStatusListener();

                        //Sign Out process
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      onCancel: () {
                        Navigator.pop(context);
                      },
                      title: "¿Desea cerrar sesión?");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

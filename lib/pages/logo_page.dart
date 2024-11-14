import 'package:flutter/material.dart';
import 'package:google_maps_taxi_driver/components/buttons/custom_elevated_button.dart';

class LogoPage extends StatelessWidget {
  const LogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomElevatedButton(
          backgroundColor: Colors.blue,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/auth_wrapper',
            );
          },
          text: const Text("Ir a Wraper"),
          textStyle: const  TextStyle(),
        ),
      ),
    );
  }
}

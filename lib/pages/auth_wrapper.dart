import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_taxi_driver/pages/driver_app.dart';
import 'package:google_maps_taxi_driver/pages/email_verification_page.dart';
import 'package:google_maps_taxi_driver/pages/log_in_page.dart';
import 'package:logger/logger.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  void rebuild() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Logger logger = Logger();
    //  final AuthService authService = AuthService();
    return Scaffold(

      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //Indicador de carga mientras se espera la conexion
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          //El usuario esta autenticado?
          if (snapshot.hasData) {
            User? user = snapshot.data;
            logger.i(
                "User verified: ${user?.emailVerified}, ${user?.uid}, user: ${user?.email}");
            // Check if the user's email is verified
            if (user != null && user.emailVerified) {
              return const DriverApp(); // Proceed to the Driver app if email is verified
            } else {
              return EmailVerificationPage(
                rebuild: rebuild,
              );
            }
            // logger.e("User already logged in");
            // return const DriverApp();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

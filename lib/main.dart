import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_maps_taxi_driver/controllers/dependency_injection.dart';
import 'package:google_maps_taxi_driver/pages/auth_wrapper.dart';
import 'package:google_maps_taxi_driver/pages/password_recovery_page.dart';
import 'package:google_maps_taxi_driver/pages/sign_up_page.dart';
import 'package:google_maps_taxi_driver/providers/map_provider.dart';
import 'package:google_maps_taxi_driver/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  runApp(ChangeNotifierProvider(
    create: (context) => MapDataProvider(),
    child: const MyApp(),
  ));
  DependencyInjection.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/auth_wrapper',
      theme: lightMode,
      darkTheme: darkMode,
      routes: {
        //  '/logo_page': (context) => const LogoPage(),
        '/auth_wrapper': (context) => const AuthWrapper(),
        '/password_recovery': (context) => const PasswordRecoveryPage(),
        '/sign-up': (context) => const SignUpPage(),
      },
    );
  }
}

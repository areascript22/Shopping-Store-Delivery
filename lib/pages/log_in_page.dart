import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_taxi_driver/components/buttons/custom_elevated_button.dart';
import 'package:google_maps_taxi_driver/components/square_tile.dart';
import 'package:google_maps_taxi_driver/controllers/network_controller.dart';
import 'package:google_maps_taxi_driver/services/auth_service.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  final Logger logger = Logger();
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  bool _isObscured = true;
  bool _isLoading = false;
  final networkController = Get.find<NetworkController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          // Wrap the content in a Form
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  //lOGO

                  SizedBox(
                    height: 140,
                    child: Image.asset(
                      'assets/img/taxi.png',
                    ),
                  ),
                  //Welcome message
                  const SizedBox(height: 30),
                  Text(
                    "Iniciar Sesión",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 30),
                  // Email TextFormField with validation
                  TextFormField(
                    style: const TextStyle(color: Colors.black),
                    controller: emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese su correo electrónico'; // Required validation
                      }
                      // Email format validation
                      const emailPattern =
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                      final emailRegex = RegExp(emailPattern);
                      if (!emailRegex.hasMatch(value)) {
                        return 'Por favor, ingrese un correo electrónico válido';
                      }
                      return null; // Return null if validation passes
                    },
                  ),
                  const SizedBox(height: 15),
                  // Password TextFormField with validation
                  TextFormField(
                    style: const TextStyle(color: Colors.black),
                    controller: passwordController,
                    obscureText: _isObscured,
                    decoration: InputDecoration(
                      // labelStyle: const TextStyle(color: Colors.black),
                      //floatingLabelStyle: const TextStyle(color: Colors.black),
                      hintText: 'Contraseña',
                      hintStyle: const TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,

                      fillColor: Colors.grey[200],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured
                              ? Ionicons.eye_off_outline
                              : Ionicons.eye_outline,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese su contraseña'; // Required validation
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 8 caracteres'; // Length validation
                      }
                      return null; // Return null if validation passes
                    },
                  ),
                  const SizedBox(height: 10),
                  // Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          //Navigate to password recovery page
                          Navigator.pushNamed(context, '/password_recovery');
                        },
                        child: Text(
                          "Olvidaste la contraseña?",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Login Button
                  CustomElevatedButton(
                    onTap: () async {
                      // Validate the form

                      if (!networkController.isConnecterToInternet.value) {
                        return;
                      }
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() {
                          _isLoading = true;
                        });
                        User? user = await _auth.loginWithEmailAndPassword(
                            emailController.text, passwordController.text);
                        if (user != null) {
                          logger.e(
                              "Sending verification email : ${user.emailVerified}");

                          if (!user.emailVerified) {
                            await _auth.sendVerificationEmail(user);
                            logger.i("Email just verified....");
                          }
                        } else {
                          //Toast

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Usuario no registrado")));
                          }
                        }
                        _isLoading = false;
                      }
                    },
                    text: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: !_isLoading
                          ? const Text(
                              "Iniciar sesion",
                              style: TextStyle(color: Colors.white),
                            )
                          : const CircularProgressIndicator(),
                    ),
                    backgroundColor: Colors.blue,
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 30),

                  //Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          //Navigate to password recovery page
                          Navigator.pushNamed(context, '/sign-up');
                        },
                        child: Text(
                          "Aun no tienes una cuenta?",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),

                  // Divider with Google Sign In
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("O continue con"),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(imagePath: 'assets/img/google_logo.png'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

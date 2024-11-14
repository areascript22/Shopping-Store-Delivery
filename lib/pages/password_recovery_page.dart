import 'package:flutter/material.dart';
import 'package:google_maps_taxi_driver/components/buttons/custom_elevated_button.dart';
import 'package:google_maps_taxi_driver/services/auth_service.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  _PasswordRecoveryPageState createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  final Logger logger = Logger();
  final _formKey = GlobalKey<FormState>(); // Form key for validation
 // bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Form(
          // Wrap the content in a Form
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Ionicons.key_outline,
                    size: 150,
                  ),
                  Text(
                    "Recupere su contraseña",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text("Le enviaremos un Email para reestablecer su contraseña",
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 20),
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

                  const SizedBox(height: 30),
                  // Login Button
                  CustomElevatedButton(
                    onTap: () async {
                      // Validate the form
                      if (_formKey.currentState?.validate() ?? false) {
                        await _auth.sendPasswordRecoveryEmail(
                            emailController.text, context);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    text: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        "Recuperar contraseña",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    backgroundColor: Colors.blue,
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 30),
                  // Divider with Google Sign In
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
                      // const Padding(
                      //   padding: EdgeInsets.all(8.0),
                      //   child: Text("O continue con"),
                      // ),
                      Expanded(
                        child: Divider(color: Colors.grey[400]),
                      ),
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

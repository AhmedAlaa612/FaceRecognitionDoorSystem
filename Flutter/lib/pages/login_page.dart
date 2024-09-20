import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iot/constants.dart';
import 'package:iot/pages/home_page.dart';
import 'package:iot/pages/register_page.dart';
import 'package:iot/widgets/custom_button.dart';
import 'package:iot/widgets/custom_text_filed.dart';
/**/
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  static String id = '/LoginPage';

  @override
  State<LoginPage> createState() => _LoginPageState();
}
 
class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          children: [
            const Spacer(flex: 1),
            Image.asset('assets/images/scholar.png'),
            const SizedBox(height: 8),
            const Text(
              "IOT application",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontFamily: 'Pacifico',
              ),
            ),
            const Spacer(flex: 2),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "LOGIN",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextFormField(
                    controller: _emailController,
                    hintText: "Email",
                    validator: (data) {
                      if (data == null || data.isEmpty) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  CustomTextFormField(
                    controller: _passwordController,
                    hintText: "Password",
                    isPassword: true,
                    validator: (data) {
                      if (data == null || data.isEmpty || data.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 75),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: 'Login',
                    onTap: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() {
                          isLoading = true;
                        });

                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();

                        try {
                          UserCredential userCredential = await FirebaseAuth
                              .instance
                              .signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          Navigator.pushNamed(context, HomePage.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login process succeeded.'),
                            ),
                          );
                          // Navigator.pushReplacementNamed(context, '/homePage');
                        } on FirebaseAuthException catch (e) {
                          String errorMessage;
                          if (e.code == 'user-not-found') {
                            errorMessage = 'No user found for that email.';
                          } else if (e.code == 'wrong-password') {
                            errorMessage =
                                'Wrong password provided for that user.';
                          } else {
                            errorMessage =
                                'An unexpected error occurred: ${e.code}';
                          }
                          showSnackBar(context, errorMessage);
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }

                        // Clear the text fields
                        _emailController.clear();
                        _passwordController.clear();
                      } else {
                        showSnackBar(
                            context, 'Please fill in all fields correctly.');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, RegisterPage.id); // Correct routing to replace current page
                        },
                        child: const Text(
                          "\tRegister here",
                          style: TextStyle(
                            color: Color.fromARGB(255, 56, 67, 63),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iot/pages/login_page.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:iot/constants.dart';
import 'package:iot/pages/home_page.dart';
import 'package:iot/widgets/custom_text_filed.dart';
import 'package:iot/widgets/custom_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  static String id = '/registerPage';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "REGISTER",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
              CustomButton(
                onTap: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() {
                      isLoading = true;
                    });

                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    try {
                      await registerUser(email, password);
                      Navigator.pushNamed(context, HomePage.id);
                    } on FirebaseAuthException catch (e) {
                      showSnackBar(context,
                          'There was an error: ${e.code.toString()}');
                    } catch (e) {
                      showSnackBar(context, 'An unexpected error occurred.');
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  } else {
                    showSnackBar(
                        context, 'Please fill in all fields correctly.');
                  }
                },
                text: 'SIGN UP',
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, LoginPage.id);
                    },
                    child: const Text(
                      "\tLogin",
                      style: TextStyle(color: Color.fromARGB(255, 56, 67, 63)),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
            ],
          ),
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

  Future<void> registerUser(String email, String password) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign-up process succeeded.'),
      ),
    );
  }
}

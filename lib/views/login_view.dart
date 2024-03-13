import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/firebase_options.dart';
import 'package:carerassistant/utilities/dialogs/error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  // Create init late vars
  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  // Dispose of vars when page is no longer rendered
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 15),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                hintText: "Email",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                fillColor: Colors.blue.withOpacity(0.2),
                filled: true,
                prefixIcon: const Icon(Icons.door_front_door)),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
                hintText: "Password",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                fillColor: Colors.blue.withOpacity(0.2),
                filled: true,
                prefixIcon: const Icon(Icons.lock)),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                final userCredential = await FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                        email: email, password: password);
                devtools.log(userCredential.toString());
                //print(userCredential);

                // remove everything on screen and display next screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  homeRoute,
                  (route) => false,
                );
              } on FirebaseAuthException catch (e) {
                if (e.code == 'User not found') {
                  await showErrorDialog(context, 'User not found');
                  devtools.log('User not found');
                  //print('User not found');
                } else if (e.code == 'wrong-password') {
                  await showErrorDialog(context, 'wrong-password');
                  devtools.log('Wrong password');
                  //print('Wrong password');
                } else {
                  await showErrorDialog(context, 'Error: ${e.code}');
                  devtools.log('Something Else Happened');
                  //print('Something Else Happened');
                }
              } catch (e) {
                devtools.log('Error: ' + e.toString());
              }
            },
            /*
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.8),
            ),
            */
            child: const Text(
              'Log in',
              selectionColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // remove everything on screen and display next screen
              Navigator.of(context).pushNamedAndRemoveUntil(
                registerRoute,
                (route) => false,
              );
            },
            child:
                const Text('Register Instead', style: TextStyle(fontSize: 15)),
          )
        ],
      ),
    );
  }
}

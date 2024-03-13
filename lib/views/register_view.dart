import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/firebase_options.dart';
import 'package:carerassistant/utilities/dialogs/error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.grey[300],
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
              prefixIcon: const Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                final userCredential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                        email: email, password: password);
                print(userCredential);
                final user = FirebaseAuth.instance.currentUser;
                await user?.sendEmailVerification();
                // add option of returning from mistake inputted
                Navigator.of(context).pushNamed(verifyEmailRoute);
              } on FirebaseAuthException catch (e) {
                if (e.code == 'weak-password') {
                  await showErrorDialog(context, 'User not found');
                  devtools.log('User not found');
                } else if (e.code == 'email-already-in-use') {
                  await showErrorDialog(context, 'Email already in use');
                  devtools.log('Email already in use');
                } else if (e.code == 'invalid-email') {
                  await showErrorDialog(context, 'Email is invalid');
                  devtools.log('Email is invalid');
                } else {
                  devtools.log('Unhandled Error:');
                  await showErrorDialog(context, 'Error ${e.code}');
                  print(e.code);
                }
              }
            },
            child: const Text('Register'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // remove everything on screen and display next screen
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text('Login instead'),
          )
        ],
      ),
    );
  }
}

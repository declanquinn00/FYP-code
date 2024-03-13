import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/firebase_options.dart';
import 'package:carerassistant/views/edit_profile_screen.dart';
import 'package:carerassistant/views/entries/edit_entry_view.dart';
import 'package:carerassistant/views/profile_screen.dart';
import 'package:carerassistant/views/entries/entry_view.dart';
import 'package:carerassistant/views/login_view.dart';
import 'package:carerassistant/views/entries/create_update_entry_view.dart';
import 'package:carerassistant/views/register_view.dart';
//import 'package:carerassistant/views/verify_email_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:path/path.dart';

void main() {
  // initialize firebase
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        homeRoute: (context) => const EntryView(),
        createOrUpdateEntryRoute: (context) => const CreateUpdateEntryView(),
        profileViewRoute: (context) => const ProfileScreenView(),
        editProfileViewRoute: (context) => const EditProfileScreenView(),
        editEntryRoute: (context) => const EditEntryView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            devtools.log(user.toString());

            // DEBUG !!!!!
            //return const ProfileScreenView();

            if (user != null) {
              // Reload Users Status
              devtools.log('Email is Verified');
              return const EntryView();
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}

enum MenuAction { logout }

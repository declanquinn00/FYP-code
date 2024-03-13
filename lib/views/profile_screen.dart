import 'dart:io';
import 'dart:typed_data';

import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/services/entity_service_exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools show log;

class ProfileScreenView extends StatefulWidget {
  const ProfileScreenView({super.key});

  @override
  State<ProfileScreenView> createState() => _ProfileScreenViewState();
}

class _ProfileScreenViewState extends State<ProfileScreenView> {
  Uint8List? _imageA;
  Uint8List? _imageB;
  late final _name;
  late final _content;
  late final DatabaseService _databaseService;
  late DatabaseProfile? _profile;

  String userEmail() {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        // user has to have an email
        return user.email!;
      } else {
        throw EmailNotFound();
      }
    } catch (e) {
      throw EmailNotFound();
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final email = userEmail();
      // !!! REPLACE WITH EMAIL !!!
      DatabaseUser user = await _databaseService.getUser(email: email);
      int userID = user.id;
      _profile = await _databaseService.getProfile(userID: userID);
      if (_profile != null) {
        setState(() {
          _imageA = _profile!.PhotoA != null ? _profile!.PhotoA! : null;
          _imageB = _profile!.PhotoB != null ? _profile!.PhotoB! : null;
        });
      }
    } catch (e) {
      devtools.log('Error loading profile data: $e');
    }
  }

  // open the database
  @override
  void initState() {
    _databaseService = DatabaseService();
    _profile = null;
    _loadProfileData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(editProfileViewRoute, (_) => false);
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(homeRoute, (_) => false);
            },
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              //_profile.Title,
              _profile != null && _profile!.Title.isNotEmpty
                  ? _profile!.Title
                  : 'Your Profile',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_imageA != null && _imageA!.isNotEmpty) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Fullscreen(image: _imageA!),
                            ));
                      }
                    },
                    child: _imageA != null && _imageA!.isNotEmpty
                        ? Image.memory(
                            _imageA!,
                            width: 150,
                            height: 150,
                          )
                        : FlutterLogo(size: 160),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_imageB != null && _imageB!.isNotEmpty) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Fullscreen(image: _imageB!),
                            ));
                      }
                    },
                    child: _imageB != null && _imageB!.isNotEmpty
                        ? Image.memory(
                            _imageB!,
                            width: 150,
                            height: 150,
                          )
                        : FlutterLogo(size: 160),
                  ),
                ),
              ],
            ),
            Text(
              // !!!
              _profile != null && _profile!.Description.isNotEmpty
                  ? _profile!.Description
                  : 'Enter a description',
            ),
          ],
        ),
      ),
    );
  }
}

// fullscreen image
class Fullscreen extends StatelessWidget {
  final Uint8List image;
  const Fullscreen({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image View'),
      ),
      body: Center(
        child: Image.memory(image),
      ),
    );
  }
}

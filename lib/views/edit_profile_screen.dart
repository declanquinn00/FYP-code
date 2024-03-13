import 'dart:io';
import 'dart:typed_data';

import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/services/entity_service_exceptions.dart';
import 'package:carerassistant/utilities/dialogs/error_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools show log;

class EditProfileScreenView extends StatefulWidget {
  const EditProfileScreenView({super.key});

  @override
  State<EditProfileScreenView> createState() => _EditProfileScreenViewState();
}

class _EditProfileScreenViewState extends State<EditProfileScreenView> {
  File? _imageA;
  File? _imageB;
  Uint8List? _imageALoaded;
  Uint8List? _imageBLoaded;
  late final _name;
  late final _content;
  late final DatabaseService _databaseService;
  late final DatabaseProfile? _profile;

  // Create init late vars
  @override
  void initState() {
    _name = TextEditingController();
    _content = TextEditingController();
    _databaseService = DatabaseService();
    _loadProfileData();
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _content.dispose();
    super.dispose();
  }

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
      // !!! REPLACE WITH EMAIL !!!
      final email = userEmail();
      DatabaseUser user = await _databaseService.getUser(email: email);
      int userID = user.id;
      devtools.log('Loading Profile Data');
      _profile = await _databaseService.getProfile(userID: userID);
      devtools.log('Profile Data loaded');
      if (_profile != null) {
        setState(() {
          _imageALoaded = _profile?.PhotoA != null ? _profile!.PhotoA : null;
          _imageBLoaded = _profile?.PhotoB != null ? _profile!.PhotoB : null;
          _name.text = _profile!.Title.isNotEmpty ? _profile!.Title : '';
          _content.text =
              _profile!.Description.isNotEmpty ? _profile!.Description : '';
        });
        devtools.log('Image Data loaded');
      } else {
        devtools.log('Profile was empty');
      }
    } catch (e) {
      devtools.log('Error loading profile data: $e');
    }
  }

  Future<void> saveProfileData() async {
    try {
      String title = _name.text;
      String description = _content.text;
      Uint8List photoABytes = _imageA != null
          ? await _imageA!.readAsBytes()
          : _imageALoaded != null
              ? _imageALoaded!
              : Uint8List(0);
      Uint8List photoBBytes = _imageB != null
          ? await _imageB!.readAsBytes()
          : _imageBLoaded != null
              ? _imageBLoaded!
              : Uint8List(0);

      final email = userEmail();
      // !!! REPLACE WITH EMAIL !!!
      DatabaseUser user = await _databaseService.getUser(email: email);
      int userID = user.id;
/*
      //
      // DEBUG delete a profile
      devtools.log('DELETING PROFILE');
      await _databaseService.deleteProfile(userID: userID);
      devtools.log('PROFILE DELETED');
      return;
      //
*/
      try {
        DatabaseProfile existingProfile =
            await _databaseService.getProfile(userID: userID);
        // If a profile exists, you can handle it here
        devtools.log('Profile already exists, updating...');
        devtools.log('Pre Updated Profile: $existingProfile');

        // Update existing profile
        await _databaseService.updateProfile(
          profile: existingProfile,
          title: title,
          description: description,
          PhotoA: photoABytes,
          PhotoB: photoBBytes,
        );
        devtools.log('Profile updated successfully');
        DatabaseProfile updatedProfile =
            await _databaseService.getProfile(userID: userID);
        devtools.log('Post Updated Profile: $updatedProfile');

        return;
      } catch (e) {
        devtools.log('Profile does not exist');
      }

      // create new profile
      await _databaseService.createProfile(
        userID: userID,
        Title: title,
        PhotoA: photoABytes,
        PhotoB: photoBBytes,
        Description: description,
      );
      // !!! DEBUG
      DatabaseProfile profile =
          await _databaseService.getProfile(userID: userID);
      devtools.log('Saved Profile: $profile');
    } catch (e) {
      devtools.log('Updating Profile Error: $e');
    }
  }

  Future<File?> selectImage(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(
          source: source, imageQuality: 25, requestFullMetadata: false);
      if (photo == null) {
        return null;
      } else {
        final selectedPhoto = File(photo.path);
        final size = selectedPhoto.lengthSync();
        final maxSize = 2 * 1024 * 1024; // 2 MB after compression!
        if (size <= maxSize) {
          return selectedPhoto;
        } else {
          await showErrorDialog(context, 'File too large');
          return null;
        }
      }
    } catch (e) {
      devtools.log('An Error Occurred in Selecting Image ' + e.toString());
      await showErrorDialog(context, 'An error occurred uploading this image');
      return null;
    }
  }

/*
  Future selectImageA(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);
      if (photo == null) {
        return null;
      } else {
        final selectedPhoto = File(photo.path);
        final size = selectedPhoto.lengthSync();
        final maxSize = 2 * 1024 * 1024; // 2 MB
        if (size <= maxSize) {
          setState(() {
            _imageA = selectedPhoto;
          });
        } else {
          await showErrorDialog(context, 'File too large');
        }
      }
    } catch (e) {
      devtools.log('An Error Occurred in Selecting Image ' + e.toString());
    }
  }

  Future selectImageB(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);
      if (photo == null) {
        return null;
      } else {
        final selectedPhoto = File(photo.path);
        final size = selectedPhoto.lengthSync();
        final maxSize = 2 * 1024 * 1024; // 2 MB
        if (size <= maxSize) {
          setState(() {
            _imageB = selectedPhoto;
          });
        } else {
          await showErrorDialog(context, 'File too large');
        }
      }
    } catch (e) {
      devtools.log('An Error Occurred in Selecting Image ' + e.toString());
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () async {
              devtools.log('SaveProfileData');
              await saveProfileData();
              devtools.log('Create/update profile complete');
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(profileViewRoute, (route) => false);
            },
            icon: const Icon(Icons.check),
          ),
          IconButton(
            onPressed: () {
              // Do nothing
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(profileViewRoute, (route) => false);
            },
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadProfileData(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _name,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Profile Name',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                            child: GestureDetector(
                          onTap: () async {
                            final image =
                                await selectImage(ImageSource.gallery);
                            if (image != null) {
                              setState(() {
                                _imageA = image;
                              });
                            }
                          },
                          child: _imageA != null
                              ? Image.file(
                                  key: UniqueKey(),
                                  _imageA!,
                                  width: 150,
                                  height: 150,
                                )
                              : (_imageALoaded != null &&
                                      _imageALoaded!.isNotEmpty)
                                  ? Image.memory(
                                      key: UniqueKey(),
                                      _imageALoaded!,
                                      width: 150,
                                      height: 150,
                                    )
                                  : FlutterLogo(size: 160),
                        )),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final image =
                                  await selectImage(ImageSource.gallery);
                              if (image != null) {
                                setState(() {
                                  _imageB = image;
                                });
                              }
                            },
                            child: _imageB != null
                                ? Image.file(
                                    key: UniqueKey(),
                                    _imageB!,
                                    width: 150,
                                    height: 150,
                                  )
                                : (_imageBLoaded != null &&
                                        _imageBLoaded!.isNotEmpty)
                                    ? Image.memory(
                                        key: UniqueKey(),
                                        _imageBLoaded!,
                                        width: 150,
                                        height: 150,
                                      )
                                    : FlutterLogo(size: 160),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _content,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          hintText: 'Enter a profile description'),
                    ),
                  ],
                ),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/utilities/dialogs/error_dialog.dart';
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
  late final NotesService _notesService;
  late final DatabaseProfile? _profile;

  // Create init late vars
  @override
  void initState() {
    _name = TextEditingController();
    _content = TextEditingController();
    _notesService = NotesService();
    _loadProfileData();
    // Fill fields if profile is not null
/*
    if (_profile != null) {
      if (_profile!.Title.isNotEmpty) {
        _name.text = _profile!.Title;
      }
      if (_profile!.Description.isNotEmpty) {
        _content.text = _profile!.Description;
      }
    }
*/
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      // !!! REPLACE WITH EMAIL !!!
      DatabaseUser user = await _notesService.getUser(email: 'quinnd13@tcd.ie');
      int userID = user.id;
      devtools.log('Loading Profile Data');
      _profile = await _notesService.getProfile(userID: userID);
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

      // !!! REPLACE WITH EMAIL !!!
      DatabaseUser user = await _notesService.getUser(email: 'quinnd13@tcd.ie');
      int userID = user.id;
/*
      //
      // DEBUG delete a profile
      devtools.log('DELETING PROFILE');
      await _notesService.deleteProfile(userID: userID);
      devtools.log('PROFILE DELETED');
      return;
      //
*/
      try {
        DatabaseProfile existingProfile =
            await _notesService.getProfile(userID: userID);
        // If a profile exists, you can handle it here
        devtools.log('Profile already exists, updating...');
        devtools.log('Pre Updated Profile: $existingProfile');

        // Update existing profile
        await _notesService.updateProfile(
          profile: existingProfile,
          title: title,
          description: description,
          PhotoA: photoABytes,
          PhotoB: photoBBytes,
        );
        devtools.log('Profile updated successfully');
        DatabaseProfile updatedProfile =
            await _notesService.getProfile(userID: userID);
        devtools.log('Post Updated Profile: $updatedProfile');

        return;
      } catch (e) {
        devtools.log('Profile does not exist');
      }

      // create new profile
      await _notesService.createProfile(
        userID: userID,
        Title: title,
        PhotoA: photoABytes,
        PhotoB: photoBBytes,
        Description: description,
      );
      // !!! DEBUG
      DatabaseProfile profile = await _notesService.getProfile(userID: userID);
      devtools.log('Saved Profile: $profile');
    } catch (e) {
      devtools.log('Updating Profile Error: $e');
    }
  }

  Future selectImageA(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);
      if (photo == null) {
        return null;
      } else {
        final selectedPhoto = File(photo.path);
        final size = selectedPhoto.lengthSync();
        final maxSize = 1 * 1024 * 1024; // 10 MB
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
        final maxSize = 1 * 1024 * 1024; // 10 MB
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
      body: SingleChildScrollView(
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
                  onTap: () {
                    selectImageA(ImageSource.gallery);
                  },
                  /*
                  child: _imageALoaded != null && _imageALoaded!.isNotEmpty
                      ? _imageA != null
                          ? Image.file(
                              key: UniqueKey(),
                              _imageA!,
                              width: 150,
                              height: 150,
                            )
                          : Image.memory(
                              key: UniqueKey(),
                              _imageALoaded!,
                              width: 150,
                              height: 150,
                            )
                      : FlutterLogo(size: 160),
                      */
                  child: _imageA != null
                      ? Image.file(
                          key: UniqueKey(),
                          _imageA!,
                          width: 150,
                          height: 150,
                        )
                      : (_imageALoaded != null && _imageALoaded!.isNotEmpty)
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
                    onTap: () {
                      selectImageB(ImageSource.gallery);
                    },
                    child: _imageB != null
                        ? Image.file(
                            key: UniqueKey(),
                            _imageB!,
                            width: 150,
                            height: 150,
                          )
                        : (_imageBLoaded != null && _imageBLoaded!.isNotEmpty)
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
      ),
    );
  }
}

import 'dart:io';

import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools show log;

class ProfileScreenView extends StatefulWidget {
  const ProfileScreenView({super.key});

  @override
  State<ProfileScreenView> createState() => _ProfileScreenViewState();
}

class _ProfileScreenViewState extends State<ProfileScreenView> {
  File? _imageA;
  File? _imageB;
  late final NotesService _notesService;

  // open the database
  @override
  void initState() {
    _notesService = NotesService();
    super.initState();
  }
/*
  @override
  void dispose() {
    _notesService.close();
    super.dispose();
  }
*/

  Future selectImageA(ImageSource source) async {
    try {
      final photo = await ImagePicker().pickImage(source: source);
      if (photo == null) {
        return null;
      } else {
        final selectedPhoto = File(photo.path);

        setState(() {
          _imageA = selectedPhoto;
        });
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
        setState(() {
          _imageB = selectedPhoto;
        });
      }
    } catch (e) {
      devtools.log('An Error Occurred in Selecting Image ' + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    editProfileViewRoute, (_) => false);
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
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'This is your profile',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _imageA != null
                      ? Image.file(
                          _imageA!,
                          width: 150,
                          height: 150,
                        )
                      : FlutterLogo(size: 160),
                ),
                Expanded(
                  child: _imageB != null
                      ? Image.file(
                          _imageB!,
                          width: 150,
                          height: 150,
                        )
                      : FlutterLogo(size: 160),
                ),
              ],
            ),
            const Text('Blah'),
          ],
        ));
  }
}

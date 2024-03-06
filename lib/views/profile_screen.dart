import 'dart:io';

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
        appBar: AppBar(title: const Text('Profile')),
        body: Column(
          children: [
            Spacer(),
            _imageA != null
                ? Image.file(
                    _imageA!,
                    width: 150,
                    height: 150,
                  )
                : FlutterLogo(size: 160),
            _imageB != null
                ? Image.file(
                    _imageB!,
                    width: 150,
                    height: 150,
                  )
                : FlutterLogo(size: 160),
            const SizedBox(height: 24),
            Text(
              'This is your profile',
              style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            TextButton(
                onPressed: () {
                  selectImageA(ImageSource.gallery);
                },
                child: const Text('Select photo from gallery')),
            TextButton(
                onPressed: () {
                  selectImageB(ImageSource.camera);
                },
                child: const Text('Select photo from camera'))
          ],
        ));
  }
}

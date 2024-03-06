import 'dart:io';

import 'package:carerassistant/constants/routes.dart';
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
  late final _name;
  late final _content;

  // Create init late vars
  @override
  void initState() {
    _name = TextEditingController();
    _content = TextEditingController();
    super.initState();
  }

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
              // Save new Values and pass to DB
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
                  child: _imageA != null
                      ? Image.file(
                          _imageA!,
                          width: 150,
                          height: 150,
                        )
                      : FlutterLogo(size: 160),
                )),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      selectImageB(ImageSource.camera);
                    },
                    child: _imageB != null
                        ? Image.file(
                            _imageB!,
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

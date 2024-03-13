import 'dart:io';
import 'dart:typed_data';

import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/utilities/dialogs/error_dialog.dart';
import 'package:carerassistant/utilities/generics/get_arguments.dart';
import 'package:carerassistant/views/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:image_picker/image_picker.dart';

class EditEntryView extends StatefulWidget {
  const EditEntryView({super.key});

  @override
  State<EditEntryView> createState() => _EditEntryViewState();
}

class _EditEntryViewState extends State<EditEntryView> {
  // ensure entries are not created multiple times on hot reload
  DatabaseEntry? _entry;
  File? _imageA;
  File? _imageB;
  Uint8List? _imageALoaded;
  Uint8List? _imageBLoaded;
  late final DatabaseService _databaseService;
  late final TextEditingController _textController;
  late final TextEditingController _titleController;
  @override
  void initState() {
    _databaseService = DatabaseService();
    _textController = TextEditingController();
    _titleController = TextEditingController();
    super.initState();
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
*/
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

  Future<DatabaseEntry> createOrGetExistingEntry(BuildContext context) async {
    // check if entry exists
    devtools.log('Getting or creating Database Entry');
    if (_entry == null) {
      final widgetEntry = context.getArgument<DatabaseEntry>();
      // pull any existing entry
      if (widgetEntry != null) {
        devtools.log('Getting Database Entry');
        _entry = widgetEntry;
        _textController.text = widgetEntry.text;
        _titleController.text = widgetEntry.title;
        // !!! RETURN imageAloaded and b setup
        _imageALoaded = widgetEntry.photoA;
        _imageBLoaded = widgetEntry.photoB;
        return widgetEntry;
      }
      // else create new entry
      final existingEntry = _entry;
      if (existingEntry != null) {
        return existingEntry;
      }
      devtools.log("No existing Entry, creating new one...");
      final currentUser =
          FirebaseAuth.instance.currentUser!; // we expect a current user here
      final email = currentUser.email!;
      devtools.log("Email: " + email);
      // !!!!!!!
      final owner = await _databaseService.getUser(email: email);
      devtools.log("Owner found");
      final newEntry = await _databaseService.createEntry(owner: owner);
      _entry = newEntry;
      final entryId = _entry!.id.toString();
      devtools.log('DEBUG Entry ID $entryId');
      return newEntry;
    } else {
      devtools.log('Existing Entry found!');
      final entryId = _entry!.id.toString();
      devtools.log('DEBUG Entry ID $entryId');
      return _entry!;
    }
  }

  void _deleteEntryIfTitleIsEmpty() {
    final entry = _entry;
    if (_titleController.text.isEmpty && entry != null) {
      _databaseService.deleteEntry(id: entry.id);
    }
  }

  Future<void> _saveEntry(BuildContext context) async {
    try {
      final widgetEntry = context.getArgument<DatabaseEntry>();
      final id = widgetEntry!.id;
      String title = _titleController.text;
      String text = _textController.text;

      // DEBUG !!!
      devtools.log('Value of imageABytes: $_imageA');

      Uint8List imageABytes = _imageA != null
          ? await _imageA!.readAsBytes()
          : _imageALoaded != null
              ? _imageALoaded!
              : Uint8List(0);
      Uint8List imageBBytes = _imageB != null
          ? await _imageB!.readAsBytes()
          : _imageBLoaded != null
              ? _imageBLoaded!
              : Uint8List(0);

      // Get Current Entry ID

      await _databaseService.updateEntry(
        entry: widgetEntry,
        text: text,
        title: title,
        photoA: imageABytes,
        photoB: imageBBytes,
      );
      devtools.log('Saved Successfully!');
      DatabaseEntry newWidgetEntry = await _databaseService.getEntry(id: id);
      Navigator.pop(context, newWidgetEntry);
    } catch (e) {
      devtools.log('Error saving Entry: $e');
    }
  }

  // logi for removing entries
  @override
  void dispose() {
    _deleteEntryIfTitleIsEmpty();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Edit Entry'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () async {
              await _saveEntry(context);
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: FutureBuilder(
        future: createOrGetExistingEntry(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              //_setupTextControllerListener();
              //_setupTitleControllerListener();
              return SingleChildScrollView(
                child: Column(children: [
                  TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: 'Title...')),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // !!! RETURN convert into one function
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
                        ),
                      ),
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
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(hintText: 'Type here...'),
                    maxLines: null,
                  ),
                ]),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

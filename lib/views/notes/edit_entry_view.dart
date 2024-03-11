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
  // ensure notes are not created multiple times on hot reload
  DatabaseEntry? _note;
  File? _imageA;
  File? _imageB;
  Uint8List? _imageALoaded;
  Uint8List? _imageBLoaded;
  late final NotesService _notesService;
  late final TextEditingController _textController;
  late final TextEditingController _titleController;
  @override
  void initState() {
    _notesService = NotesService();
    _textController = TextEditingController();
    _titleController = TextEditingController();
    super.initState();
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

  Future<DatabaseEntry> createOrGetExistingNote(BuildContext context) async {
    // check if note exists
    devtools.log('Getting or creating Database Entry');
    if (_note == null) {
      final widgetNote = context.getArgument<DatabaseEntry>();
      // pull any existing note
      if (widgetNote != null) {
        devtools.log('Getting Database Entry');
        _note = widgetNote;
        _textController.text = widgetNote.text;
        _titleController.text = widgetNote.title;
        // !!! RETURN imageAloaded and b setup
        _imageALoaded = widgetNote.photoA;
        _imageBLoaded = widgetNote.photoB;
        return widgetNote;
      }
      // else create new note
      final existingNote = _note;
      if (existingNote != null) {
        return existingNote;
      }
      devtools.log("No existing Note, creating new one...");
      final currentUser =
          FirebaseAuth.instance.currentUser!; // we expect a current user here
      final email = currentUser.email!;
      devtools.log("Email: " + email);
      // !!!!!!!
      final owner = await _notesService.getUser(email: email);
      devtools.log("Owner found");
      final newNote = await _notesService.createNote(owner: owner);
      _note = newNote;
      final noteId = _note!.id.toString();
      devtools.log('DEBUG Note ID $noteId');
      return newNote;
    } else {
      devtools.log('Existing Note found!');
      final noteId = _note!.id.toString();
      devtools.log('DEBUG Note ID $noteId');
      return _note!;
    }
  }

  void _deleteNoteIfTitleIsEmpty() {
    final note = _note;
    if (_titleController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
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

      await _notesService.updateNote(
        note: widgetEntry,
        text: text,
        title: title,
        photoA: imageABytes,
        photoB: imageBBytes,
      );
      devtools.log('Saved Successfully!');
      DatabaseEntry newWidgetEntry = await _notesService.getNote(id: id);
      Navigator.pop(context, newWidgetEntry);
    } catch (e) {
      devtools.log('Error saving Entry: $e');
    }
  }

  // logi for removing/saving notes
  @override
  void dispose() {
    _deleteNoteIfTitleIsEmpty();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

/*
  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && text.isNotEmpty) {
      await _notesService.updateNote(
        note: note,
        text: text,
      );
    }
    ;
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
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
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              //_setupTextControllerListener();
              //_setupTitleControllerListener();
              return Column(children: [
                TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Title...')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // !!! RETURN convert into one function
                          selectImageA(ImageSource.gallery);
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
              ]);
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/utilities/generics/get_arguments.dart';
import 'package:carerassistant/views/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

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

/*
  // when textcontroller is called run this script
  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
    await _notesService.updateNote(
      note: note,
      text: text,
    );
  }

  // removes and recreates textcontroller listener
  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  void _titleControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final title = _titleController.text;
    await _notesService.updateNote(
      note: note,
      text: title,
    );
  }

  // removes and recreates textcontroller listener
  void _setupTitleControllerListener() {
    _textController.removeListener(_titleControllerListener);
    _textController.addListener(_titleControllerListener);
  }
*/
  Future<DatabaseEntry> createOrGetExistingNote(BuildContext context) async {
    // get an existing note
    final widgetNote = context.getArgument<DatabaseEntry>();
    // If note already exists recreate it
    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }
    // otherwise create new note
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
    return newNote;
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  Future<void> _saveEntry(BuildContext context) async {
    try {
      final widgetEntry = context.getArgument<DatabaseEntry>();
      final id = widgetEntry!.id;
      String title = _titleController.text;
      String text = _textController.text;
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
      Navigator.pop(context, widgetEntry);
    } catch (e) {
      devtools.log('Error saving Entry: $e');
    }
  }

  // logi for removing/saving notes
  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    //_saveNoteIfTextNotEmpty();
    _textController.dispose();
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
                        onTap: () {},
                        child: FlutterLogo(size: 160),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: FlutterLogo(size: 160),
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

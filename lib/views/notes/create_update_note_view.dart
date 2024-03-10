import 'dart:typed_data';

import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/utilities/generics/get_arguments.dart';
import 'package:carerassistant/views/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  // ensure notes are not created multiple times on hot reload
  DatabaseEntry? _note;
  late final NotesService _notesService;
  @override
  void initState() {
    _notesService = NotesService();
    super.initState();
  }

  Future<void> _updateChanges() async {
    final note = await _notesService.getNote(id: _note!.id);
    setState(() {
      _note = note;
    });
  }

  Future<DatabaseEntry> createOrGetExistingNote(BuildContext context) async {
    // get an existing note
    final widgetNote = context.getArgument<DatabaseEntry>();
    // If note already exists recreate it
    if (widgetNote != null) {
      _note = widgetNote;
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
    if (note != null && note.title.isEmpty) {
      _notesService.deleteNote(id: note.id);
    }
  }

  // logi for removing/saving notes
  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(
            onPressed: () async {
              // !!! Return pushNamed!
              Navigator.of(context)
                  .pushNamed(editEntryRoute, arguments: _note)
                  .then((value) {
                devtools.log('Returned to note updating values');
                _updateChanges();
              });
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Column(children: [
                Text(
                  _note != null && _note!.title.isNotEmpty
                      ? _note!.title
                      : 'Title...',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
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
                Text(
                  // !!!
                  _note != null && _note!.text.isNotEmpty
                      ? _note!.text
                      : 'Type here...',
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

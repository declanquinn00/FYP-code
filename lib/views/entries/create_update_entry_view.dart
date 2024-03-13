import 'dart:typed_data';

import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/utilities/generics/get_arguments.dart';
import 'package:carerassistant/views/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class CreateUpdateEntryView extends StatefulWidget {
  const CreateUpdateEntryView({super.key});

  @override
  State<CreateUpdateEntryView> createState() => _CreateUpdateEntryViewState();
}

class _CreateUpdateEntryViewState extends State<CreateUpdateEntryView> {
  // ensure notes are not created multiple times on hot reload
  DatabaseEntry? _note;
  late final DatabaseService _notesService;

  @override
  void initState() {
    _notesService = DatabaseService();
    super.initState();
  }

  Future<void> _updateChanges() async {
    devtools.log('Updating Changes...');
    final note = await _notesService.getEntry(id: _note!.id);
    setState(() {
      _note = note;
    });
  }

  Future<DatabaseEntry> createOrGetExistingNote(BuildContext context) async {
    // get an existing note
    if (_note == null) {
      devtools.log("Going through this again...");
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
      final newNote = await _notesService.createEntry(owner: owner);
      _note = newNote;
      final noteId = _note!.id.toString();
      devtools.log('DEBUG Note ID $noteId');

      return newNote;
    } else {
      return _note!;
    }
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (note != null && note.title.isEmpty) {
      _notesService.deleteEntry(id: note.id);
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
        title: const Text('Entry'),
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
              return SingleChildScrollView(
                child: Column(children: [
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
                          onTap: () {
                            if (_note != null &&
                                _note!.photoA != null &&
                                _note!.photoA!.isNotEmpty) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Fullscreen(image: _note!.photoA!),
                                  ));
                            }
                          },
                          child: _note != null &&
                                  _note!.photoA != null &&
                                  _note!.photoA!.isNotEmpty
                              ? Image.memory(
                                  _note!.photoA!,
                                  width: 150,
                                  height: 150,
                                )
                              : FlutterLogo(size: 160),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_note != null &&
                                _note!.photoB != null &&
                                _note!.photoB!.isNotEmpty) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Fullscreen(image: _note!.photoB!),
                                  ));
                            }
                          },
                          child: _note != null &&
                                  _note!.photoB != null &&
                                  _note!.photoB!.isNotEmpty
                              ? Image.memory(
                                  _note!.photoB!,
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
                    _note != null && _note!.text.isNotEmpty
                        ? _note!.text
                        : 'Type here...',
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

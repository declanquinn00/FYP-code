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
  DatabaseEntry? _entry;
  late final DatabaseService _databaseService;

  @override
  void initState() {
    _databaseService = DatabaseService();
    super.initState();
  }

  Future<void> _updateChanges() async {
    devtools.log('Updating Changes...');
    final entry = await _databaseService.getEntry(id: _entry!.id);
    setState(() {
      _entry = entry;
    });
  }

  Future<DatabaseEntry> createOrGetExistingEntry(BuildContext context) async {
    // get an existing entry
    if (_entry == null) {
      devtools.log("Going through this again...");
      final widgetEntry = context.getArgument<DatabaseEntry>();
      // If note already exists recreate it
      if (widgetEntry != null) {
        _entry = widgetEntry;
        return widgetEntry;
      }
      // otherwise create entry
      final existingEntry = _entry;
      if (existingEntry != null) {
        return existingEntry;
      }
      devtools.log("No existing Entry, creating new one...");
      final currentUser =
          FirebaseAuth.instance.currentUser!; // we expect a current user here
      final email = currentUser.email!;
      devtools.log("Email: " + email);
      final owner = await _databaseService.getUser(email: email);
      final newEntry = await _databaseService.createEntry(owner: owner);
      _entry = newEntry;
      final entryId = _entry!.id.toString();
      devtools.log('DEBUG Entry ID $entryId');

      return newEntry;
    } else {
      return _entry!;
    }
  }

  void _deleteEntryIfTextIsEmpty() {
    final Entry = _entry;
    if (Entry != null && Entry.title.isEmpty) {
      _databaseService.deleteEntry(id: Entry.id);
    }
  }

  // logi for removing/saving entries
  @override
  void dispose() {
    _deleteEntryIfTextIsEmpty();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Entry'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () async {
              // !!! Return pushNamed!
              Navigator.of(context)
                  .pushNamed(editEntryRoute, arguments: _entry)
                  .then((value) {
                devtools.log('Returned to entry updating values');
                _updateChanges();
              });
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: FutureBuilder(
        future: createOrGetExistingEntry(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return SingleChildScrollView(
                child: Column(children: [
                  Text(
                    _entry != null && _entry!.title.isNotEmpty
                        ? _entry!.title
                        : 'Title...',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_entry != null &&
                                _entry!.photoA != null &&
                                _entry!.photoA!.isNotEmpty) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Fullscreen(image: _entry!.photoA!),
                                  ));
                            }
                          },
                          child: _entry != null &&
                                  _entry!.photoA != null &&
                                  _entry!.photoA!.isNotEmpty
                              ? Image.memory(
                                  _entry!.photoA!,
                                  width: 150,
                                  height: 150,
                                )
                              : FlutterLogo(size: 160),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_entry != null &&
                                _entry!.photoB != null &&
                                _entry!.photoB!.isNotEmpty) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Fullscreen(image: _entry!.photoB!),
                                  ));
                            }
                          },
                          child: _entry != null &&
                                  _entry!.photoB != null &&
                                  _entry!.photoB!.isNotEmpty
                              ? Image.memory(
                                  _entry!.photoB!,
                                  width: 150,
                                  height: 150,
                                )
                              : FlutterLogo(size: 160),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _entry != null && _entry!.text.isNotEmpty
                        ? _entry!.text
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

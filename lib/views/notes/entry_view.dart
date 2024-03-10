import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/main.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/services/entity_service_exceptions.dart';
import 'package:carerassistant/utilities/dialogs/logout_dialog.dart';
import 'package:carerassistant/views/notes/notes_list_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

// *****!
class _NotesViewState extends State<NotesView> {
  // ****!
  String userEmail() {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null) {
        // user has to have an email
        return user.email!;
      } else {
        throw EmailNotFound();
      }
    } catch (e) {
      throw EmailNotFound();
    }
  }

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateNoteRoute);
            },
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(profileViewRoute, (route) => false);
            },
            icon: const Icon(Icons.person),
          ),
          PopupMenuButton<MenuAction>(onSelected: (value) async {
            switch (value) {
              // get result from logout dialog
              case MenuAction.logout:
                final shouldLogout = await showLogOutDialog(context);
                devtools.log(shouldLogout.toString());
                if (shouldLogout) {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                    (_) => false,
                  );
                }
                break;
            }
          }, itemBuilder: (context) {
            return [
              const PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: Text('Log out'),
              ),
            ];
          })
        ],
      ),
      body: FutureBuilder(
        // **!
        future: _notesService.getOrCreateUser(email: userEmail()),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return StreamBuilder(
                  stream: _notesService.allNotes,
                  builder: (context, snapshot) {
                    // active when returning a value
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return const Text('Waiting for All Notes');
                      case ConnectionState.active:
                        if (snapshot.hasData) {
                          final allNotes = snapshot.data as List<DatabaseEntry>;
                          return NotesListView(
                            notes: allNotes,
                            onDeleteNote: (note) async {
                              await _notesService.deleteNote(id: note.id);
                            },
                            onTap: (note) {
                              // go to this screen and pass a note
                              Navigator.of(context).pushNamed(
                                createOrUpdateNoteRoute,
                                arguments: note,
                              );
                            },
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      default:
                        return const CircularProgressIndicator();
                    }
                  });
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

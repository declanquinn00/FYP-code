import 'package:carerassistant/constants/routes.dart';
import 'package:carerassistant/main.dart';
import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/services/entity_service_exceptions.dart';
import 'package:carerassistant/utilities/dialogs/logout_dialog.dart';
import 'package:carerassistant/views/entries/entry_list_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class EntryView extends StatefulWidget {
  const EntryView({super.key});

  @override
  State<EntryView> createState() => _EntryViewState();
}

// *****!
class _EntryViewState extends State<EntryView> {
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

  late final DatabaseService _databaseService;

  // open the database
  @override
  void initState() {
    _databaseService = DatabaseService();
    //_databaseService.deleteAllEntries();
    devtools.log('[DEBUG] Deleted all entries');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(createOrUpdateEntryRoute);
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
        future: _databaseService.getOrCreateUser(email: userEmail()),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return StreamBuilder(
                  stream: _databaseService.allEntries,
                  builder: (context, snapshot) {
                    // active when returning a value
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return const Text('Waiting for All Entries');
                      case ConnectionState.active:
                        if (snapshot.hasData) {
                          final allEntries =
                              snapshot.data as List<DatabaseEntry>;
                          return EntryListView(
                            entries: allEntries,
                            onDeleteEntry: (entry) async {
                              await _databaseService.deleteEntry(id: entry.id);
                            },
                            onTap: (entry) {
                              // go to this screen and pass an entry
                              Navigator.of(context).pushNamed(
                                createOrUpdateEntryRoute,
                                arguments: entry,
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

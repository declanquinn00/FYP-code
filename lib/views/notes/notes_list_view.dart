import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/utilities/dialogs/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

// !!!!!!! Takes a note and is just a function used to tell app to delete entry
typedef NoteCallback = void Function(DatabaseEntry note);

class NotesListView extends StatelessWidget {
  final List<DatabaseEntry> notes;
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;

  const NotesListView({
    Key? key,
    required this.notes,
    required this.onDeleteNote,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        // notes list items
        return ListTile(
          onTap: () {
            onTap(note);
            devtools.log('Note tapped');
          },
          title: Text(
            note.title,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          // Delete Button
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) {
                onDeleteNote(note);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
    );
  }
}

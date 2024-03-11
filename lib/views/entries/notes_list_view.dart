import 'package:carerassistant/services/entity_service.dart';
import 'package:carerassistant/utilities/dialogs/delete_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

// !!!!!!! Takes an entry and is just a function used to tell app to delete entry
typedef EntryCallback = void Function(DatabaseEntry entry);

class EntryListView extends StatelessWidget {
  final List<DatabaseEntry> entries;
  final EntryCallback onDeleteEntry;
  final EntryCallback onTap;

  const EntryListView({
    Key? key,
    required this.entries,
    required this.onDeleteEntry,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        // entry list items
        return ListTile(
          onTap: () {
            onTap(entry);
            devtools.log('Entry tapped');
          },
          title: Text(
            entry.title,
            maxLines: 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          // Delete Button
          trailing: IconButton(
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) {
                onDeleteEntry(entry);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
    );
  }
}

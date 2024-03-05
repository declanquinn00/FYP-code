import 'package:carerassistant/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showGenericDialog<bool>(
      context: context,
      title: 'Delete',
      content: 'Do you want to delete this entry',
      optionsBuilder: () => {
            'Cancel': false,
            'Delete': true,
          }).then(
    (value) =>
        value ?? false, // Return false if dialog is closed without response
  );
}

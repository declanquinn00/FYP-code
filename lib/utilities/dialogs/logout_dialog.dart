import 'package:carerassistant/utilities/dialogs/generic_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  return showGenericDialog<bool>(
      context: context,
      title: 'Log out',
      content: 'Do you want to log out?',
      optionsBuilder: () => {
            'Cancel': false,
            'Log out': true,
          }).then(
    (value) =>
        value ?? false, // Return false if dialog is closed without response
  );
}

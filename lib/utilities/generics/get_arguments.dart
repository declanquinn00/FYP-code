import 'package:flutter/material.dart' show BuildContext, ModalRoute;

//!!! Extract arguments from build context
extension GetArgument on BuildContext {
  T? getArgument<T>() {
    final modalRoute = ModalRoute.of(this);
    if (modalRoute != null) {
      final args = modalRoute.settings.arguments;
      // ensure the args is of type T we pass
      if (args != null && args is T) {
        return args as T;
      }
    }
    return null;
  }
}

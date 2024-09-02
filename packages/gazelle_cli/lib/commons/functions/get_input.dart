import 'dart:io';

import '../entities/input_icons.dart';

/// Gets user input from the command line.
String getInput(
  /// The message to display to the user.
  String message, {
  /// The message to display to the user when the input is empty.
  String onEmpty = "Please provide a valid input to proceed!",

  /// The default value to use if the user does not provide any input.
  String? defaultValue,

  /// A function to validate the user input.
  /// Return a message to display to the user if the input is invalid.
  String? Function(String input)? validator,

  /// This function is called just before returning the input.
  /// You can use this function to modify the input before returning it.
  String Function(String input)? onValidated,

  /// The leading icon to display before the message.
  String leading = InputIcons.star,

  /// The trailing icon to display after the message.
  String trailing = InputIcons.rocket,
}) {
  String? input;
  while (true) {
    stdout.write(
        "${leading.isEmpty ? '' : '$leading '}$message ${trailing.isEmpty ? '' : '$trailing '}${defaultValue != null ? "($defaultValue)" : ""}: ");
    input = stdin.readLineSync();
    if (input == null) {
      print("Operation cancelled by the user.");
      exit(0);
    }
    if (input.isEmpty && defaultValue != null) {
      input = defaultValue;
    }
    String? validationError = validator?.call(input);
    if (input.isEmpty || validationError != null) {
      stdout.writeln("${InputIcons.warning}  ${validationError ?? onEmpty}");
    } else {
      break;
    }
  }
  return onValidated?.call(input) ?? input;
}

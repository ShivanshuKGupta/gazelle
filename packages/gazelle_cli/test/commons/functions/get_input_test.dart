import 'dart:io';

import 'package:gazelle_cli/commons/functions/get_input.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockStdin extends Mock implements Stdin {}

void main() {
  group('getInput', () {
    test('should return correct user input', () {
      final mockStdin = MockStdin();

      when(() => mockStdin.readLineSync()).thenReturn('input!');

      IOOverrides.runZoned(
        () {
          String input = getInput('Enter something:');
          expect(input, equals('input!'));
        },
        stdin: () => mockStdin,
      );
    });

    test('should return default value if user input is empty', () {
      final mockStdin = MockStdin();

      when(() => mockStdin.readLineSync()).thenReturn('');

      IOOverrides.runZoned(
        () {
          String input = getInput('Enter something:', defaultValue: 'default');
          expect(input, equals('default'));
        },
        stdin: () => mockStdin,
      );
    });

    test('should return modified input', () {
      final mockStdin = MockStdin();

      when(() => mockStdin.readLineSync()).thenReturn('input!');

      IOOverrides.runZoned(
        () {
          String input = getInput(
            'Enter something:',
            onValidated: (input) => input.toUpperCase(),
          );
          expect(input, equals('INPUT!'));
        },
        stdin: () => mockStdin,
      );
    });
  });
}

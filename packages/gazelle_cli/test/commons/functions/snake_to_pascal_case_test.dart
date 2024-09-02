import 'package:gazelle_cli/commons/functions/snake_to_pascal_case.dart';
import 'package:test/test.dart';

void main() {
  test("snake to pascal case", () {
    final snakeCases = [
      "snake_case",
      "_snake_case",
      "snake_case_",
      "__snake_case__",
      "SNAKE_cAsE",
    ];

    final pascalCase = "SnakeCase";

    for (final snakeCase in snakeCases) {
      expect(snakeToPascalCase(snakeCase), pascalCase);
    }
  });
}

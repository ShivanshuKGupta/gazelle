import 'dart:convert';

import 'package:gazelle_cli/commons/functions/get_latest_package_version.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('GetLatestPackageVersion tests', () {
    test('Should return the latest package version from the pub.dev api',
        () async {
      final originalVersion =
          await http.get(Uri.parse('https://pub.dev/api/packages/http')).then(
                (response) => jsonDecode(response.body)['latest']['version'],
              );

      final version = await getLatestPackageVersion('http');

      expect(version, equals(originalVersion));
    });
  });
}

import 'dart:async';

import 'package:gazelle_core/gazelle_core.dart';
import 'package:gazelle_logger/gazelle_logger.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class TestLogOutput extends LogOutput {
  String outputValue = "";

  @override
  void output(OutputEvent event) => outputValue += event.lines.join("\n");
}

class _TestHandler extends GazelleRouteHandler<String> {
  final String _string;

  const _TestHandler(this._string);

  @override
  FutureOr<GazelleResponse<String>> call(
    GazelleContext context,
    GazelleRequest request,
    GazelleResponse response,
  ) {
    return GazelleResponse(
      statusCode: GazelleHttpStatusCode.success.ok_200,
      body: _string,
    );
  }
}

void main() {
  group('GazelleLoggerPlugin tests', () {
    test('Should log incoming request', () async {
      // Arrange
      final logOutput = TestLogOutput();
      final plugin = GazelleLoggerPlugin(logOutput: logOutput);

      final route = GazelleRoute(
        name: "",
        get: _TestHandler(plugin.toString()),
        preRequestHooks: (context) => [
          context.getPlugin<GazelleLoggerPlugin>().logRequestHook,
        ],
        postResponseHooks: (context) => [
          context.getPlugin<GazelleLoggerPlugin>().logResponseHook,
        ],
      );

      final app = GazelleApp(
        routes: [route],
        plugins: [plugin],
      );
      await app.start();

      // Act
      await http.get(Uri.parse("http://${app.address}:${app.port}/"));

      // Assert
      expect(logOutput.outputValue.contains("INCOMING REQUEST"), isTrue);
      expect(logOutput.outputValue.contains("OUTGOING RESPONSE"), isTrue);
      await app.stop(force: true);
    });
  });
}

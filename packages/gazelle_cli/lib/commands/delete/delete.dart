import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_spin/cli_spin.dart';

import '../../commons/entities/input_icons.dart';
import '../../commons/entities/project_configuration.dart';
import '../../commons/functions/get_input.dart';
import '../../commons/functions/load_project_configuration.dart';
import 'delete_project.dart';

/// CLI command to delete a Gazelle project.
class DeleteCommand extends Command {
  @override
  String get description => "Deleting a Gazelle project";

  @override
  String get name => "delete";

  /// Creates a [DeleteCommand].
  DeleteCommand() {
    argParser.addOption(
      "path",
      abbr: "p",
      help: "The path of the project which you want to delete.",
    );
  }

  @override
  void run() async {
    final pathOption = argResults?.option("path");
    final spinner = CliSpin(
      text: "Deleting Gazelle project...",
      spinner: CliSpinners.dots,
    ).start();
    late final ProjectConfiguration projectConfiguration;
    try {
      projectConfiguration = await loadProjectConfiguration(path: pathOption);
    } on LoadProjectConfigurationGazelleNotFoundError catch (e) {
      spinner.fail(e.errorMessage);
      exit(2);
    } on LoadProjectConfigurationPubspecNotFoundError catch (e) {
      spinner.fail(e.errorMessage);
      exit(2);
    } on Exception catch (e) {
      spinner.fail(e.toString());
      exit(2);
    }
    final answer = getInput(
      '\nAre you sure you want to delete the project ${projectConfiguration.name}? (y/n)',
      onValidated: (input) =>
          ['yes', 'y'].contains(input.toLowerCase()) ? 'y' : 'n',
      leading: InputIcons.warning,
      trailing: InputIcons.none,
      defaultValue: 'n',
    );
    if (answer == 'y') {
      spinner.fail("Project deletion aborted.");
      return;
    }
    try {
      final result = await deleteProject(path: pathOption);
      spinner.success(
        "$result project is deleted\n",
      );
    } on DeletingProjectError catch (e) {
      spinner.fail(e.message);
      exit(2);
    } on Exception catch (e) {
      spinner.fail(e.toString());
      exit(2);
    }
  }
}

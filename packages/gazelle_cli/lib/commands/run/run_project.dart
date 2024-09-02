import 'dart:convert';
import 'dart:io';

import '../../commons/consts.dart';
import '../../commons/entities/stdin_broadcast.dart';

String _getPubspecTemplate(String projectName) => """
name: temp_project
description: A temporary project for running a Gazelle project.
version: 1.0.0
publish_to: none

environment:
  sdk: ^$dartSdkVersion

dependencies:
  hotreloader: ^4.2.0
  $projectName:
    path: ../../$projectName

dev_dependencies:
""";

String _getMainTemplate(String projectName, int timeout, bool verbose) => """
/// Code Auto-Generated by Gazelle CLI
/// DO NOT MODIFY

import 'dart:convert';
import 'dart:io';

import 'package:hotreloader/hotreloader.dart';
import 'package:$projectName/$projectName.dart' as main_project;

/// Whether or not verbose output is enabled.
const verbose = $verbose;

/// Prints a message if verbose output is enabled.
void verbosePrint(dynamic message) {
  if (verbose) {
    print(message);
  }
}

/// The main entry point of the application.
void main(List<String> arguments) async {
  Directory.current = Directory.current.parent;

  final reloader = await HotReloader.create(
    automaticReload: false,
    watchDependencies: false,
    onBeforeReload: (ctx) {
      verbosePrint('Reloading...');
      return true;
    },
    onAfterReload: (ctx) => print('Reloaded'),
  );

  await _addWatchers(reloader);

  ProcessSignal.sigint.watch().listen((event) {
    verbosePrint("Stopping Reload Service...");
    reloader.stop();
    exit(0);
  });

  stdin.transform(utf8.decoder).listen((event) async {
    if (event.trim() == "r") {
      reload(reloader);
    }
  });

  await main_project.runApp(arguments);
}

/// Adds watchers to the project directory and its subdirectories.
Future<void> _addWatchers(HotReloader reloader) async {
  if (!FileSystemEntity.isWatchSupported) {
    print(
        "File system watch is not supported on this platform.\\nHot reload will not trigger automatically on file/directory changes.");
    return;
  }

  final projectDir = Directory.current.absolute.path;
  final lib = Directory("\$projectDir/lib");
  final pubspec = File("\$projectDir/pubspec.yaml");

  void onModify(FileSystemEvent event) {
    final isDirectory =
        event.isDirectory || FileSystemEntity.isDirectorySync(event.path);
    final isFile = !isDirectory;

    if (event.type == FileSystemEvent.delete) {
      verbosePrint("Ignoring delete event on '\${event.path}'.");
      return;
    }

    if (isDirectory) {
      if (event.type == FileSystemEvent.create && Platform.isLinux) {
        /// As Linux doesn't supports recursive watch,
        /// watchers on newly created directories have to be added manually
        _recursiveWatch(Directory(event.path), onModify);
      } else {
        verbosePrint("Directory '\${event.path}' modified.");
      }
    }

    if (isFile) {
      if (!event.path.endsWith('.dart') &&
          !event.path.endsWith('pubspec.yaml')) {
        verbosePrint("Ignoring '\${event.path}' as it is not a dart file.");
        return;
      }
      verbosePrint("File '\${event.path}' modified.");
    }

    reload(reloader);
  }

  pubspec.watch().listen(onModify);

  if (Platform.isLinux) {
    /// As Linux doesn't supports recursive watch, we will have to watch each
    /// directory individually
    _recursiveWatch(lib, onModify);
  } else {
    /// On Windows and MacOS, we can just watch the lib directory recursively
    lib.watch(recursive: true).listen(onModify);
  }
}

/// This executionIndex is meant for implementing debouncing
int executionIndex = 0;

/// Reloads the code after a delay.
void reload(HotReloader reloader) async {
  int tmp = ++executionIndex;
  await Future.delayed(Duration(milliseconds: $timeout));

  /// If the executionIndex has changed, then another restart was requested
  /// within the timeout period, so we will let the other restart request
  /// handle the rest and return
  if (tmp != executionIndex) return;

  reloader.reloadCode();
}

/// Recursively watches a directory and its subdirectories.
void _recursiveWatch(Directory dir, Function(FileSystemEvent) onModify) {
  verbosePrint("Watching directory: \${dir.path}");
  dir.watch().listen(onModify);
  dir.listSync().whereType<Directory>().forEach((subDir) {
    _recursiveWatch(subDir, onModify);
  });
}
""";

/// Represents an error during the running process of a project.
class RunProjectError {
  /// The error message.
  final String message;

  /// The error code.
  final int errCode;

  /// Creates a [RunProjectError].
  RunProjectError(this.message, this.errCode);

  @override
  String toString() => "Error ($errCode): $message";
}

/// Runs a Gazelle project.
Future<Process?> runProject(String path, int timeout, bool verbose) async {
  final projectDir = Directory(path);
  if (!await projectDir.exists()) {
    throw RunProjectError("Project not found!", 1);
  }

  final tmpDir =
      Directory("${projectDir.absolute.path + Platform.pathSeparator}.tmp");
  if (await tmpDir.exists()) {
    await tmpDir.delete(recursive: true);
  }
  await tmpDir.create();

  final tmpDirPath = tmpDir.absolute.path;

  final projectName = path.split(Platform.pathSeparator).last;
  await File("$tmpDirPath/pubspec.yaml")
      .create(recursive: true)
      .then((file) => file.writeAsString(_getPubspecTemplate(projectName)));

  await File("$tmpDirPath/main_hot_reload.dart").create(recursive: true).then(
      (file) =>
          file.writeAsString(_getMainTemplate(projectName, timeout, verbose)));

  final result = await Process.run(
    "dart",
    ["pub", "get"],
    workingDirectory: tmpDirPath,
  );

  if (result.exitCode != 0) {
    throw RunProjectError(result.stderr.toString(), result.exitCode);
  }

  Process? process = await startProcess(tmpDirPath);

  stdinBroadcast.listen((event) async {
    if (event.trim() == 'R') {
      /// Hot Restart
      process?.kill();
      process = await startProcess(tmpDirPath);
    } else {
      /// Else send the input to the process, the process will be
      /// responsible for if the event is 'r' then reload the code
      process?.stdin.writeln(event);
    }
  });

  ProcessSignal.sigint.watch().listen((event) {
    process?.kill();
    exit(0);
  });

  return process;
}

/// Starts the temporary project process.
///
/// It also assigns basic event listeners to the process.
Future<Process> startProcess(String tmpProjectDir) async {
  final process = await Process.start(
    "dart",
    ["run", "--enable-vm-service", "main_hot_reload.dart"],
    workingDirectory: tmpProjectDir,
  );

  process.stdout.transform(utf8.decoder).listen((event) {
    stdout.write(event);
  });

  process.stderr.transform(utf8.decoder).listen((event) {
    stdout.write(event);
  });

  process.exitCode.then((exitCode) {
    print("Process exited with code $exitCode");
  });

  return process;
}

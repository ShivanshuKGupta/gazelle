import 'dart:io';

/// Gazelle Core package name.
const gazelleCorePackageName = "gazelle_core";

/// Gazelle Serialization package name.
const gazelleSerializationPackageName = "gazelle_serialization";

/// Gazelle Client package name.
const gazelleClientPackageName = "gazelle_client";

/// Returns the Currently Installed Dart SDK version.
final String dartSdkVersion = Platform.version.split(' ').first;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

final Map<String, Version?> _byDirectory = {};

/// The language version of the package containing the file at [path]: the
/// lower bound of `environment: sdk:` in the nearest `pubspec.yaml`, as
/// `major.minor.0`. `null` when there is no pubspec or no SDK lower bound.
///
/// Newer language versions reject code older ones accept (for example
/// `final` on a function parameter), so sources must be parsed at their
/// package's version, as the Dart tools do.
Version? packageLanguageVersion(String path) {
  if (path.isEmpty) return null;
  return _forDirectory(p.dirname(p.absolute(path)));
}

Version? _forDirectory(String dir) => _byDirectory.putIfAbsent(dir, () {
  final pubspec = File(p.join(dir, 'pubspec.yaml'));
  if (pubspec.existsSync()) return _sdkLowerBound(pubspec);
  final parent = p.dirname(dir);
  return parent == dir ? null : _forDirectory(parent);
});

Version? _sdkLowerBound(File pubspec) {
  try {
    final yaml = loadYaml(pubspec.readAsStringSync());
    final environment = yaml is YamlMap ? yaml['environment'] : null;
    final sdk = environment is YamlMap ? environment['sdk'] : null;
    if (sdk is! String) return null;
    final constraint = VersionConstraint.parse(sdk);
    final min = constraint is VersionRange ? constraint.min : null;
    return min == null ? null : Version(min.major, min.minor, 0);
  } on Exception {
    return null;
  }
}

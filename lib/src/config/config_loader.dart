import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'config.dart';

part 'config_scalars.dart';
part 'gate_config_readers.dart';
part 'gate_config_readers_extra.dart';
part 'gate_config_readers_flutter.dart';

/// Top-level and section keys of `crap_dart.yaml`.
const String _crapKey = 'crap';
const String _coverageKey = 'coverage';
const String _profileKey = 'profile';
const String _sourcesKey = 'sources';
const String _runTestsKey = 'run_tests';
const String _gatesKey = 'gates';
const String _thresholdMsKey = 'threshold_ms';

/// Error raised for malformed or invalid `crap_dart.yaml` content.
class ConfigException implements Exception {
  /// Creates a [ConfigException].
  const ConfigException(this.path, this.key, this.message);

  /// Path of the config file that failed to load.
  final String path;

  /// The offending key (dot-separated for nested keys).
  final String key;

  /// Human readable description of the problem.
  final String message;

  @override
  String toString() => 'Invalid config "$path": $key: $message';
}

/// Loads `crap_dart.yaml` with strict validation and per-key defaults.
class ConfigLoader {
  /// Creates a [ConfigLoader].
  const ConfigLoader();

  /// Default config file name looked up in the project root.
  static const String configFileName = 'crap_dart.yaml';

  /// Config file name of crap_dart's predecessor, crap4dart, still read
  /// when [configFileName] is absent.
  static const String legacyConfigFileName = 'crap4dart.yaml';

  /// Known gate identifiers under the `gates` key.
  static const Set<String> knownGates = {
    'loc',
    'test_coverage',
    'golden',
    'hardcoded_strings',
    'accessibility',
    'complexity',
    'method_size',
    'nesting',
    'class_size',
    'weight_of_class',
    'unused_code',
    'unused_files',
    'banned_imports',
    'public_docs',
    'duplication',
    'file_naming',
    'magic_constants',
    'broken_goldens',
    'test_assertions',
    'folder_structure',
    'external',
  };

  /// Loads the configuration for the project at [projectRoot].
  ///
  /// When [configPath] is given, that file is loaded and must exist.
  /// Otherwise `<projectRoot>/crap_dart.yaml` is used when present, then
  /// the legacy `crap4dart.yaml`; a missing file is not an error and
  /// yields [CrapDartConfig.defaults].
  ///
  /// Throws a [ConfigException] on unknown keys or wrongly typed values.
  CrapDartConfig load(String projectRoot, {String? configPath}) {
    final path = configPath ?? defaultConfigPath(projectRoot);
    final file = File(path);
    if (!file.existsSync()) {
      if (configPath != null) {
        throw ConfigException(path, path, 'config file not found');
      }
      return CrapDartConfig.defaults();
    }
    return loadString(file.readAsStringSync(), path: path);
  }

  /// The config file of [projectRoot]: `crap_dart.yaml`, or
  /// `crap4dart.yaml` when only that one exists.
  static String defaultConfigPath(String projectRoot) {
    final current = p.join(projectRoot, configFileName);
    final legacy = p.join(projectRoot, legacyConfigFileName);
    return !File(current).existsSync() && File(legacy).existsSync()
        ? legacy
        : current;
  }

  /// Parses and validates config [content] (used with [path] in errors).
  CrapDartConfig loadString(String content, {String path = configFileName}) {
    final Object? doc;
    try {
      doc = loadYaml(content);
    } on YamlException catch (e) {
      throw ConfigException(path, path, 'invalid YAML: ${e.message}');
    }
    if (doc == null) return CrapDartConfig.defaults();
    final root = _ConfigScalars.asMap(doc, path, '(root)');
    _ConfigScalars.checkKeys(
      root,
      const {
        _crapKey,
        _coverageKey,
        _gatesKey,
        _profileKey,
        _sourcesKey,
        'exclude',
      },
      path,
      '',
    );
    final defaults = CrapDartConfig.defaults();
    return CrapDartConfig(
      crap: _readCrap(root[_crapKey], defaults.crap, path),
      coverage: _readCoverage(root[_coverageKey], defaults.coverage, path),
      gates: _readGates(root[_gatesKey], defaults.gates, path),
      profile: _readProfile(root[_profileKey], defaults.profile, path),
      sources: _readSources(root[_sourcesKey], defaults.sources, path),
      exclude: _ConfigScalars.strList(
        root,
        'exclude',
        defaults.exclude,
        path,
        '',
      ),
    );
  }

  List<String> _readSources(Object? node, List<String> base, String path) {
    if (node == null) return base;
    if (node is! YamlList) {
      throw ConfigException(path, _sourcesKey, 'expected a list of strings');
    }
    final sources = <String>[];
    for (final entry in node.nodes) {
      final value = entry is YamlScalar ? entry.value : null;
      if (value is! String || value.isEmpty) {
        throw ConfigException(
          path,
          _sourcesKey,
          'expected a list of non-empty strings',
        );
      }
      sources.add(value);
    }
    return sources;
  }

  CrapConfig _readCrap(Object? node, CrapConfig base, String path) {
    if (node == null) return base;
    final map = _ConfigScalars.asMap(node, path, _crapKey);
    _ConfigScalars.checkKeys(
      map,
      const {
        _enabledKey,
        'threshold',
        _runTestsKey,
        'count_lambdas',
        'count_constructors',
      },
      path,
      _crapKey,
    );
    return CrapConfig(
      enabled: _ConfigScalars.readBool(
        map,
        _enabledKey,
        base.enabled,
        path,
        _crapKey,
      ),
      threshold: _ConfigScalars.readNum(
        map,
        'threshold',
        base.threshold,
        path,
        _crapKey,
      ),
      runTests: _ConfigScalars.readBool(
        map,
        _runTestsKey,
        base.runTests,
        path,
        _crapKey,
      ),
      countLambdas: _ConfigScalars.readBool(
        map,
        'count_lambdas',
        base.countLambdas,
        path,
        _crapKey,
      ),
      countConstructors: _ConfigScalars.readBool(
        map,
        'count_constructors',
        base.countConstructors,
        path,
        _crapKey,
      ),
    );
  }

  CoverageConfig _readCoverage(Object? node, CoverageConfig base, String path) {
    if (node == null) return base;
    final map = _ConfigScalars.asMap(node, path, _coverageKey);
    _ConfigScalars.checkKeys(
      map,
      const {
        'lcov_path',
        _runTestsKey,
        'required',
        'branch_coverage',
        'unloaded_as_uncovered',
      },
      path,
      _coverageKey,
    );
    return CoverageConfig(
      lcovPath: _ConfigScalars.str(
        map,
        'lcov_path',
        base.lcovPath,
        path,
        _coverageKey,
      ),
      runTests: _ConfigScalars.readBool(
        map,
        _runTestsKey,
        base.runTests,
        path,
        _coverageKey,
      ),
      required: _ConfigScalars.readBool(
        map,
        'required',
        base.required,
        path,
        _coverageKey,
      ),
      branchCoverage: _ConfigScalars.readBool(
        map,
        'branch_coverage',
        base.branchCoverage,
        path,
        _coverageKey,
      ),
      unloadedAsUncovered: _ConfigScalars.readBool(
        map,
        'unloaded_as_uncovered',
        base.unloadedAsUncovered,
        path,
        _coverageKey,
      ),
    );
  }

  ProfileConfig _readProfile(Object? node, ProfileConfig base, String path) {
    if (node == null) return base;
    final map = _ConfigScalars.asMap(node, path, _profileKey);
    _ConfigScalars.checkKeys(
      map,
      const {_enabledKey, _thresholdMsKey, 'top'},
      path,
      _profileKey,
    );
    final thresholdValue = map[_thresholdMsKey];
    double? thresholdMs;
    if (thresholdValue != null) {
      thresholdMs = _ConfigScalars.readNum(
        map,
        _thresholdMsKey,
        base.thresholdMs ?? 0,
        path,
        _profileKey,
      );
    }
    final topRaw = map['top'];
    return ProfileConfig(
      enabled: _ConfigScalars.readBool(
        map,
        _enabledKey,
        base.enabled,
        path,
        _profileKey,
      ),
      thresholdMs: thresholdMs,
      top: topRaw == null
          ? null
          : _ConfigScalars.readInt(
              map,
              'top',
              base.top ?? 20,
              path,
              _profileKey,
            ),
    );
  }

  GatesConfig _readGates(Object? node, GatesConfig base, String path) {
    if (node == null) return base;
    final map = _ConfigScalars.asMap(node, path, _gatesKey);
    for (final key in map.keys) {
      if (!knownGates.contains(key)) {
        throw ConfigException(path, 'gates.$key', 'unknown gate id');
      }
    }
    return _GateConfigReaders.readGates(map, base, path);
  }
}

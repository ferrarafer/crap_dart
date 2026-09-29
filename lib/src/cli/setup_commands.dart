part of 'runner.dart';

/// The `init` command: writes a default `crap_dart.yaml` config file.
class InitCommand extends Command<int> {
  /// Creates an [InitCommand].
  InitCommand({this.projectRoot}) {
    argParser.addFlag(
      _forceFlag,
      abbr: 'f',
      negatable: false,
      help: 'Overwrite an existing config file.',
    );
  }

  /// Project root override (default: the current working directory).
  final String? projectRoot;

  @override
  final String name = 'init';

  @override
  final String description =
      'Create a default crap_dart.yaml config file in the current directory.';

  @override
  int run() {
    final root = projectRoot ?? Directory.current.path;
    final path = p.join(root, ConfigLoader.configFileName);
    final file = File(path);
    if (file.existsSync() && !(argResults![_forceFlag] as bool)) {
      stderr.writeln(
        '${ConfigLoader.configFileName} already exists '
        '(use --force to overwrite).',
      );
      return ExitCodes.usageError;
    }
    file.writeAsStringSync(defaultConfigTemplate);
    stdout.writeln('Created ${ConfigLoader.configFileName}');
    return ExitCodes.success;
  }
}

/// The `install` command: installs git hooks and CI workflow templates.
class InstallCommand extends Command<int> {
  /// Creates an [InstallCommand].
  InstallCommand({this.projectRoot}) {
    argParser
      ..addOption(
        'hook',
        defaultsTo: 'pre-commit',
        help: 'Name of the git hook to install.',
      )
      ..addFlag(
        'ci',
        negatable: false,
        help: 'Also install the GitHub Actions quality workflow.',
      )
      ..addFlag(
        _forceFlag,
        abbr: 'f',
        negatable: false,
        help: 'Merge into existing hooks / overwrite existing files.',
      )
      ..addOption(_configFlag, help: _configHelp);
  }

  /// Project root override (default: the current working directory).
  final String? projectRoot;

  @override
  final String name = 'install';

  @override
  final String description =
      'Install the pre-commit hook and (with --ci) the CI workflow.';

  @override
  Future<int> run() async {
    final projectRoot = this.projectRoot ?? Directory.current.path;
    try {
      final config = const ConfigLoader().load(
        projectRoot,
        configPath: argResults![_configFlag] as String?,
      );
      final force = argResults![_forceFlag] as bool;
      final hookPath = await const HookInstaller().installHook(
        projectRoot,
        hookName: argResults!['hook'] as String,
        force: force,
        runTests: config.coverage.runTests,
      );
      stdout.writeln('Installed git hook: ${_relative(hookPath)}');
      if (argResults!['ci'] as bool) {
        final workflowPath = const CiInstaller().installCi(
          projectRoot,
          force: force,
        );
        stdout.writeln('Installed CI workflow: ${_relative(workflowPath)}');
      }
      return ExitCodes.success;
    } on ConfigException catch (e) {
      stderr.writeln(e);
      return ExitCodes.usageError;
    } on HookInstallException catch (e) {
      stderr.writeln(e);
      return ExitCodes.usageError;
    }
  }

  String _relative(String path) =>
      p.relative(path, from: projectRoot ?? Directory.current.path);
}

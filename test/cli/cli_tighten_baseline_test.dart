import 'dart:io';

import 'package:crap_dart/src/cli/exit_codes.dart';
import 'package:test/test.dart';

import 'cli_test_utils.dart';

void main() {
  group('check --tighten-baseline', () {
    late Directory root;

    setUp(() {
      root = createCliTestProject();
      writeCleanProject(root);
      File(
        '${root.path}/lib/dirty.dart',
      ).writeAsStringSync('void dirty() {}\n');
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('drops fixed violations and checks against the result', () async {
      await runCliInProcess(root, ['check', '--save-baseline']);
      File('${root.path}/lib/dirty.dart').deleteSync();
      final result = await runCliInProcess(root, [
        'check',
        '--tighten-baseline',
      ]);
      expect(result.exitCode, ExitCodes.success);
      expect(result.stderr, contains('Baseline tightened'));
      final baseline = File('${root.path}/.crap-baseline.json');
      expect(baseline.readAsStringSync(), isNot(contains('dirty')));
    });

    test('fails without a baseline file', () async {
      final result = await runCliInProcess(root, [
        'check',
        '--tighten-baseline',
      ]);
      expect(result.exitCode, ExitCodes.usageError);
      expect(result.stderr, contains('--save-baseline first'));
    });

    test('refuses a partial selection', () async {
      await runCliInProcess(root, ['check', '--save-baseline']);
      await gitInitAndCommit(root, 'base');
      File('${root.path}/lib/dirty.dart').writeAsStringSync('void d2() {}\n');
      final result = await runCliInProcess(root, [
        'check',
        '--changed',
        '--tighten-baseline',
      ]);
      expect(result.exitCode, ExitCodes.usageError);
      expect(result.stderr, contains('needs a full run'));
    });
  });
}

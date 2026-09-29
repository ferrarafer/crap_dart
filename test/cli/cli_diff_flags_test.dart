import 'dart:io';

import 'package:test/test.dart';

import 'cli_test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() => tempDir = createCliTestProject());
  tearDown(() => tempDir.deleteSync(recursive: true));

  test('--diff conflicts with --changed and --staged', () async {
    writeCleanProject(tempDir);
    await gitInitAndCommit(tempDir, 'base');
    for (final flag in ['--changed', '--staged']) {
      final result = await runCliInProcess(tempDir, ['check', '--diff', flag]);
      expect(result.exitCode, 1, reason: flag);
    }
  });
}

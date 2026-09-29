import 'package:crap4dart/src/cli/exit_codes.dart';
import 'package:test/test.dart';

import 'cli_test_utils.dart';

void main() {
  test('profile forwards --tags and --exclude-tags to the runner', () async {
    final root = createCliProfileProject();
    addTearDown(() => root.deleteSync(recursive: true));
    final captured = <List<String>>[];
    final result = await runCliInProcessWithProfile(root, [
      'profile',
      '--tags',
      'integration, slow',
      '--exclude-tags',
      'nightly',
    ], capturingSlowRunner(captured));
    expect(result.exitCode, ExitCodes.success);
    final args = captured.single;
    expect(args, containsAll(['--tags', 'integration,slow', '-x', 'nightly']));
  });
}

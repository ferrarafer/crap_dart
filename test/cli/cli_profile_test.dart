import 'dart:io';

import 'package:crap_dart/src/cli/exit_codes.dart';
import 'package:test/test.dart';

import 'cli_test_utils.dart';

void main() {
  test('profile prints a report and exits 0', () async {
    final root = createCliProfileProject();
    addTearDown(() => root.deleteSync(recursive: true));
    final result = await runCliInProcessWithProfile(root, [
      'profile',
      '--format',
      'json',
    ], fakeSlowRunner);
    expect(result.exitCode, ExitCodes.success);
    expect(result.stdout, contains('"class": "Foo"'));
    expect(result.stdout, contains('"method": "bar"'));
    expect(result.stderr, contains('profile-reports'));
    expect(result.stdout, startsWith('{'));
  });

  test('profile exits 2 when the threshold is exceeded', () async {
    final root = createCliProfileProject();
    addTearDown(() => root.deleteSync(recursive: true));
    final result = await runCliInProcessWithProfile(root, [
      'profile',
      '--threshold',
      '10.0',
      '--format',
      'json',
    ], fakeSlowRunner);
    expect(result.exitCode, ExitCodes.thresholdExceeded);
  });

  test('profile exits 0 when disabled in config', () async {
    final root = createCliProfileProject();
    addTearDown(() => root.deleteSync(recursive: true));
    File(
      '${root.path}/crap_dart.yaml',
    ).writeAsStringSync('profile:\n  enabled: false\n');
    final result = await runCliInProcessWithProfile(root, [
      'profile',
    ], fakeSlowRunner);
    expect(result.exitCode, ExitCodes.success);
    expect(result.stdout, contains('Profiling disabled'));
  });

  test('profile --top limits the methods shown', () async {
    final root = createCliProfileProject();
    addTearDown(() => root.deleteSync(recursive: true));
    final result = await runCliInProcessWithProfile(root, [
      'profile',
      '--top',
      '5',
    ], fakeSlowRunner);
    expect(result.exitCode, ExitCodes.success);
  });

  test('profile rejects an invalid --top value', () async {
    final root = createCliProfileProject();
    addTearDown(() => root.deleteSync(recursive: true));
    final result = await runCliInProcessWithProfile(root, [
      'profile',
      '--top',
      'abc',
    ], fakeSlowRunner);
    expect(result.exitCode, ExitCodes.usageError);
    expect(result.stderr, contains('Invalid --top value'));
  });
}

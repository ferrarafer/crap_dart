import 'dart:io';

import 'package:crap_dart/src/config/config_loader.dart';
import 'package:crap_dart/src/hooks/hook_installer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'hooks/hook_test_utils.dart';

/// crap_dart still reads what its predecessor crap4dart wrote.
void main() {
  late Directory tempDir;

  setUp(() => tempDir = createHooksTestProject());
  tearDown(() => tempDir.deleteSync(recursive: true));

  void write(String name, String content) =>
      File(p.join(tempDir.path, name)).writeAsStringSync(content);

  test('crap4dart.yaml is read when crap_dart.yaml is absent', () {
    write('crap4dart.yaml', 'crap:\n  threshold: 12.0\n');
    expect(const ConfigLoader().load(tempDir.path).crap.threshold, 12.0);
    write('crap_dart.yaml', 'crap:\n  threshold: 9.0\n');
    expect(
      const ConfigLoader().load(tempDir.path).crap.threshold,
      9.0,
      reason: 'crap_dart.yaml wins when both exist',
    );
  });

  test('install replaces a crap4dart hook block', () async {
    await createGitRepo(tempDir);
    File(hookPath(tempDir)).writeAsStringSync(
      '#!/bin/sh\n'
      'echo before\n'
      '# >>> crap4dart >>>\ncrap4dart check --staged\n# <<< crap4dart <<<\n'
      'echo after\n',
    );
    await const HookInstaller().installHook(tempDir.path);
    final content = File(hookPath(tempDir)).readAsStringSync();
    expect(content, isNot(contains('crap4dart')));
    expect(HookInstaller.beginMarker.allMatches(content), hasLength(1));
    expect(content, contains('echo before'));
    expect(content, contains('echo after'));
  });
}

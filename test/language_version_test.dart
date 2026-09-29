import 'dart:io';

import 'package:crap_dart/src/analysis/dart_parser.dart';
import 'package:crap_dart/src/analysis/language_version.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

/// Valid up to Dart 3.12, rejected by the latest language version.
const _finalParameter = 'void f({final bool x = false}) {}\n';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('crap_dart_lang_'));
  tearDown(() => root.deleteSync(recursive: true));

  String write(String relative, String content) {
    final file = File(p.join(root.path, relative))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
    return file.path;
  }

  test('reads the SDK lower bound of the nearest pubspec', () {
    write('pkg/pubspec.yaml', 'name: pkg\nenvironment:\n  sdk: ^3.9.2\n');
    final file = write('pkg/lib/src/deep/a.dart', _finalParameter);
    expect(packageLanguageVersion(file), Version(3, 9, 0));
  });

  test('parses at the package language version', () {
    write(
      'pkg/pubspec.yaml',
      'name: pkg\nenvironment:\n  sdk: ">=3.9.0 <4.0.0"\n',
    );
    final file = write('pkg/lib/a.dart', _finalParameter);
    final parsed = DartParser().parse(content: _finalParameter, path: file);
    expect(parsed.unit.declarations, hasLength(1));
  });

  test('without a usable pubspec the latest version applies', () {
    for (final (dir, pubspec) in [
      ('none', null),
      ('no_env', 'name: x\n'),
      ('any', 'name: x\nenvironment:\n  sdk: any\n'),
      ('broken', 'name: [\n'),
    ]) {
      if (pubspec != null) write('$dir/pubspec.yaml', pubspec);
      final file = write('$dir/lib/a.dart', _finalParameter);
      expect(
        packageLanguageVersion(file),
        dir == 'none' ? anything : isNull,
        reason: dir,
      );
    }
    expect(packageLanguageVersion(''), isNull);
    expect(
      () => DartParser().parse(content: _finalParameter, path: ''),
      throwsA(isA<DartParseException>()),
    );
  });
}
